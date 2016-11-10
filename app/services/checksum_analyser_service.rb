require 'find'

class ChecksumAnalyserService
  def self.check_checksums_for_files(files_array)
    puts "checking checksums..."

    puts "---------------------------------------------------------------"

    checksum_check_count = 0
    checksum_successes_count = 0
    checksum_failures_count = 0
    checksum_noread_count = 0
    failed_checksum_paths = []
    noread_checksum_paths = []

    files_array.each do |file_data_hash|
      if file_data_hash[:file].include?('-checksum-') && file_data_hash[:file].include?('.txt')
        checksum_check_count += 1

        begin
          check_result_string = Dir.chdir("#{file_data_hash[:destination_path]}") {
            %x[md5sum -c #{file_data_hash[:destination_path]}#{file_data_hash[:file]}]
          }
        rescue StandardError => e
          puts 'error while checking the checksum'
        end

        unless check_result_string
          checksum_noread_count += 1

          noread_checksum_paths.push(file_data_hash[:destination_path] + file_data_hash[:file])

          puts "#{file_data_hash[:destination_path]}#{file_data_hash[:file]} cannot be read"

          next
        end

        check_result_array = check_result_string.split("\n")

        check_result_array.each do |result|
          if result.include?(' OK')
            checksum_successes_count += 1
          elsif result.include?(' FAILED')
            checksum_failures_count += 1

            failed_checksum_paths.push(file_data_hash[:destination_path] + result)

            puts "#{file_data_hash[:destination_path]}#{result}"
          end
        end
      end
    end

    puts '---------------------------------------------------------------'

    if checksum_check_count > 0
      puts "#{checksum_check_count} .txt checksum files were checked"

      puts '---------------------------------------------------------------'

      puts "#{checksum_successes_count}/#{checksum_check_count} checksums succeeded"
      puts "#{checksum_failures_count}/#{checksum_check_count} checksums failed"
      puts "#{checksum_noread_count}/#{checksum_check_count} checksums couldn't be read"

      if failed_checksum_paths.any?
        puts '!-------------------------------------------------------------!'
        puts 'files that failed the checksum:'

        failed_checksum_paths.each do |checksum_path|
          puts checksum_path
        end
      end

      if noread_checksum_paths.any?
        puts '!-------------------------------------------------------------!'
        puts 'files that could not be read:'

        noread_checksum_paths.each do |checksum_path|
          puts checksum_path
        end
      end
    else
      puts "no checksum files were checked."
    end

    true
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
