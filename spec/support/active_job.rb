RSpec.configure do |config|
  # The test env runs ActiveJob inline, so creating a Collection/Item fires CatalogMetadataJob
  # which uploads a RO-Crate to S3. Specs that only need the records (not the upload) can opt out
  # with `:no_catalog_upload` to avoid depending on S3/AWS credentials being configured.
  config.around(:each, :no_catalog_upload) do |example|
    adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
  ensure
    ActiveJob::Base.queue_adapter = adapter
  end
end
