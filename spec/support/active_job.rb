RSpec.configure do |config|
  # The test adapter stands in for :inline, which cannot enqueue a job for the future and so refuses
  # a debounced one. Told to perform both as they arrive, it runs a job the moment it is enqueued,
  # scheduled or not, which is what :inline did.
  config.before(:suite) do
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true
  end

  # Creating a Collection/Item fires CatalogMetadataJob, which uploads a RO-Crate to S3. Specs that
  # only need the records (not the upload) can opt out with `:no_catalog_upload`, which swaps in an
  # adapter that only enqueues, to avoid depending on S3/AWS credentials being configured.
  config.around(:each, :no_catalog_upload) do |example|
    adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
  ensure
    ActiveJob::Base.queue_adapter = adapter
  end
end
