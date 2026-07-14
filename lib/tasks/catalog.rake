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

  desc 'Validate Catalog vs Mediaflux'
  task check_mediaflux: :environment do
    validator = CatalogMediafluxValidatorService.new
    validator.run
  end

  desc 'Copy deposit PDFs from legacy pdsc_admin keys to collection-root keys'
  task migrate_deposit_forms: :environment do
    catalog = Nabu::Catalog.instance

    copied = 0
    already_migrated = 0
    missing = []

    Collection.where(has_deposit_form: true).find_each do |collection|
      target_key = catalog.deposit_form_key(collection)
      legacy_key = "#{collection.identifier}/pdsc_admin/#{collection.identifier}-deposit.pdf"

      if catalog.key_exists?(target_key)
        already_migrated += 1
        next
      end

      unless catalog.key_exists?(legacy_key)
        missing << collection.identifier
        next
      end

      catalog.copy_key(legacy_key, target_key)
      copied += 1
    end

    puts "Copied #{copied} deposit PDFs, #{already_migrated} already migrated"
    puts "Collections flagged has_deposit_form with no PDF at either key: #{missing.join(', ')}" if missing.any?
  end

  desc 'Remove old deleted versions'
  task remove_deleted_versions: :environment do
    env = ENV.fetch('AWS_PROFILE').sub('nabu-', '')
    service = S3VersionDeletionService.new(env)
    service.run
  end
end
