RSpec.configure do |config|
  # Specs run ActiveJob inline, so creating a Collection/Item fires CatalogMetadataJob which uploads
  # a RO-Crate to the catalog bucket in S3 (unless the spec opts out with `:no_catalog_upload`).
  # Make sure that bucket exists before the suite runs so tests don't depend on the S3 mock having
  # pre-created it (the `initialBuckets` option is unreliable) or on a persistent local volume.
  config.before(:suite) do
    s3 = Nabu::Catalog.instance.instance_variable_get(:@s3)
    s3.create_bucket(bucket: Rails.configuration.catalog_bucket)
  rescue Aws::S3::Errors::BucketAlreadyOwnedByYou, Aws::S3::Errors::BucketAlreadyExists
    # Bucket is already present (e.g. created by the S3 mock or a previous run) — nothing to do.
  end
end
