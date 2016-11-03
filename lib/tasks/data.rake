namespace :data do
  desc 'Check checksums for all files'
  task :check_all_checksums => :environment do
    ChecksumAnalyserService.check_all_checksums
  end
end
