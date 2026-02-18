namespace :catalog do
  desc 'Validate S3 vs DB'
  task check_db_s3_sync: :environment do
    exit unless Rails.env.production?

    validator = CatalogDbSyncValidatorService.new('prod')
    validator.run
  end

  desc 'Validate DR Replication'
  task check_replication: :environment do
    validator = CatalogReplicationValidatorService.new
    validator.run
  end

  desc "Mint DOIs for objects that don't have one"
  task mint_dois: :environment do
    dry_run = ENV['DRY_RUN'] ? true : false
    BatchDoiMintingService.run(dry_run)
  end

  desc 'Audit DOI URLs against DataCite and optionally update them'
  task audit_dois: :environment do
    update = ENV['UPDATE'] ? true : false
    paged = ENV['PAGED'] ? true : false
    DoiUrlAuditService.run(update:, paged:)
  end

  desc 'Fix a single DOI URL in DataCite'
  task fix_doi: :environment do
    doi = ENV.fetch('DOI') { abort 'Usage: DOI=10.26278/XXXX bin/rails catalog:fix_doi' }
    DoiUrlAuditService.fix_one(doi)
  end

  desc 'Remove old deleted versions'
  task remove_deleted_versions: :environment do
    env = ENV.fetch('AWS_PROFILE').sub('nabu-', '')
    service = S3VersionDeletionService.new(env)
    service.run
  end
end
