namespace :data do
  desc 'Check checksums for all files (one batch at a time)'
  task :check_all_checksums => :environment do
    ChecksumAnalyserService.check_in_batches
  end
end
