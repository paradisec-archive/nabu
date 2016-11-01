class ChecksumAnalyserService
  def self.check_checksums_for_files(files_array)
    puts "checking checksums..."

    puts "---------------------------------------------------------------"

    checksum_check_count = 0
    checksum_successes_count = 0
    checksum_failures_count = 0

    files_array.each do |file_data_hash|
      if file_data_hash[:file].include?('-checksum-') && file_data_hash[:file].include?('.txt')
        checksum_check_count += 1

        puts "checking checksum for #{file_data_hash[:destination_path]}#{file_data_hash[:file]}..."

        check_result_string = `md5sum -c #{file_data_hash[:destination_path]}#{file_data_hash[:file]}`
        check_result_array = check_result_string.split("\n")

        check_result_array.each do |result|
          if result.include?(' OK')
            checksum_successes_count += 1
          else
            checksum_failures_count += 1
          end

          puts "#{file_data_hash[:destination_path]}#{result}"
        end
      end
    end

    puts '---------------------------------------------------------------'

    if checksum_check_count > 0
      puts "#{checksum_check_count} txt checksum files were checked"
      puts "#{checksum_successes_count} checksums succeeded"
      puts "#{checksum_successes_count} checksums failed"
    else
      puts "no checksum files were checked"
    end
  end
end
