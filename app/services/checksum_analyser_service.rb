# files_array shape:
# [
# 	{
# 		destination_path: '/srv/catalog/COLL/ITEM1/',
# 		file: 'COLL-ITEM1-checksum-PDSC_ADMIN.txt'
# 	},
# 	{
# 		destination_path: '/srv/catalog/COLL/ITEM2/',
# 		file: 'COLL-ITEM2-checksum-PDSC_ADMIN.txt'
# 	},
# ]

class ChecksumAnalyserService
  def self.check_checksums_for_files(files_array, verbose = false)
    return if files_array.empty?

    # each checksum_file can contain multiple checksums (potentially one for each file in the item)
    total_checksums = 0
    ok_checksums = 0
    failed_checksums = 0

    failed_checksum_paths = []

    files_array.each do |file_data_hash|
      absolute_file_path = "#{file_data_hash[:destination_path]}#{file_data_hash[:file]}".gsub('//', '/')

      begin
        check_result_string = Dir.chdir("#{file_data_hash[:destination_path]}") {
          %x[ md5sum -c #{absolute_file_path} 2>&1 ]
        }
      rescue StandardError => e
        puts "[CHECKSUM] error while reading the checksum file #{file_data_hash[:file]}, unable to check if sums are valid: #{e.message}"
        next # no need to continue, we failed to even read the checksum txt file
      end

      # extract lines that have useful info
      check_result_array = check_result_string.split(/[\r\n]/).select { |line| /( OK| FAILED)/.match(line) }.map(&:chomp)
      has_failure = false
      # test if checksums passed/failed and collect failed file paths
      check_result_array.each do |result|
        total_checksums += 1

        if result.include?(' OK')
          ok_checksums += 1
        elsif result.include?(' FAILED')
          failed_checksums += 1

          failed_line = file_data_hash[:destination_path] + result
          failed_file = failed_line.split.first
          failed_checksum_paths.push({failed_file: failed_file, message: failed_line})
          has_failure = true
        end
      end # checksum results loop

      # add the checksum file itself to the failed files if it contained any failures (so that it gets moved to Rejected along with any failed checksum files)
      if has_failure
        puts "[CHECKSUM] Some checksums failed in #{absolute_file_path}" if verbose
        failed_checksum_paths.push({failed_file: "#{absolute_file_path}"})
      elsif verbose
        puts "[CHECKSUM] Successfully validated the checksums in #{absolute_file_path}"
      end

    end # checksum files loop

    puts "[CHECKSUM] Checked #{total_checksums} essence #{"checksum".pluralize(total_checksums)} in #{files_array.count} #{"file".pluralize(files_array.count)}. #{ok_checksums} passed | #{failed_checksums} failed"

    if failed_checksums > 0
      puts "[CHECKSUM] Files that failed the checksum check:"

      failed_checksum_paths.each do |failure_result|
        puts "[CHECKSUM] - #{failure_result[:message]}"
      end

      return failed_checksum_paths.map { |failure_result| failure_result[:failed_file] }
    end

    []
  end

  def self.check_all_checksums
    file_array = find_checksum_files_by_collection('**')

    self.check_checksums_for_files(file_array, true)
  end

  def self.check_in_batches(batch_size = 10)

    # calculate the set of collections to run in this batch
    last_run = last_run_collection
    batch = (
      last_run.nil? ?
        Collection.first(batch_size) :
        Collection.where('identifier > ?', last_run.identifier).first(batch_size)
    ).map(&:identifier)

    puts "[CHECKSUM] Validating checksums for collection batch: [#{batch.join(', ')}]"

    # find all checksums in these collections
    file_array = find_checksum_files_by_collection("{#{batch.join(',')}}/**")

    # update checkpoint file
    File.write(checkpoint_file, batch.last)

    self.check_checksums_for_files(file_array, true)
  end

  def self.find_checksum_files_by_collection(collection_pattern)
    Dir.glob("#{Nabu::Application.config.archive_directory}/#{collection_pattern}/*-checksum-*").map do |file_path|
      split_path = file_path.split('/')

      { destination_path: "#{split_path[0..(split_path.length - 2)].join('/')}/", file: split_path.last }
    end
  end

  def self.last_run_collection
    # if no existing run, start from beginning
    return nil unless (File.exists?(checkpoint_file))
    last_collection_checked = File.read(checkpoint_file).chomp()

    # if the last collection run was the last one in the catalog, start again
    return nil if last_collection_checked == Collection.last.identifier

    # last collection, or nil if the file contents were empty/invalid
    Collection.find_by_identifier(last_collection_checked)
  end

  def self.checkpoint_file
    "#{Rails.root}/tmp/last_collection_checked"
  end
end
