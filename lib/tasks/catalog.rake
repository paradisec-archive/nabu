namespace :catalog do
  desc 'Validate S3 vs DB'
  task check_db_s3_sync: :environment do
    env = ENV.fetch('AWS_PROFILE').sub('nabu-', '')

    validator = CatalogDbSyncValidatorService.new(env)
    validator.run
  end
end
