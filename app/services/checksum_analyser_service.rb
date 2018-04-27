require 'find'

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
  def self.check_checksums_for_files(files_array)
    return if files_array.empty?

    # each checksum_file can contain multiple checksums (potentially one for each file in the item)
    total_checksums = 0
    ok_checksums = 0
    failed_checksums = 0
    
    failed_checksum_paths = []

    files_array.each do |file_data_hash|
      begin
        check_result_string = Dir.chdir("#{file_data_hash[:destination_path]}") {
          %x[ md5sum -c #{file_data_hash[:destination_path]}#{file_data_hash[:file]} 2>&1 ]
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
          failed_file = failed_line.split(':').first
          failed_checksum_paths.push({failed_file: failed_file, message: failed_line})
          has_failure = true
        end
      end # checksum results loop

      # add the checksum file itself to the failed files if it contained any failures (so that it gets moved to Rejected along with any failed checksum files)
      failed_checksum_paths.push({failed_file: "#{file_data_hash[:destination_path]}#{file_data_hash[:file]}"}) if has_failure

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
    checksum_file_paths = []
    file_array = []

    Find.find(Nabu::Application.config.archive_directory) do |path|
      checksum_file_paths << path if (path =~ /.+\.txt/ && path =~ /-checksum-/)
    end

    checksum_file_paths.each do |file_path|
      split_path = file_path.split('/')

      file_array.push({ destination_path: "#{split_path[0..(split_path.length - 2)].join('/')}/", file: split_path.last })
    end

    self.check_checksums_for_files(file_array)
  end
end
