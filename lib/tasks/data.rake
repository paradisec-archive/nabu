namespace :data do
  desc 'Validate files on disk in the catalog are in the DB'
  task :check_ondisk_files => :environment do
    validator = CatalogDbSyncValidatorService.new
    validator.run
  end
end
