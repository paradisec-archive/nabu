namespace :catalog do
  desc 'Validate S3 vs DB'
  task check_db_s3_sync: :environment do
    exit unless Rails.env.production?

    validator = CatalogDbSyncValidatorService.new('prod')
    validator.run
  end

  desc "Mint DOIs for objects that don't have one"
  task mint_dois: :environment do
    dry_run = ENV['DRY_RUN'] ? true : false
    BatchDoiMintingService.run(dry_run)
  end
end
