class DeleteCatalogFilesJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 10

  def perform(keys, verify_prefix: nil)
    catalog = Nabu::Catalog.instance

    keys.each_slice(Nabu::Catalog::MAX_DELETE_KEYS) do |batch|
      catalog.delete_keys(batch)
      Rails.logger.info "[DELETE] Removed #{batch.size} catalog files"
    end

    return unless verify_prefix

    strays = catalog.list_keys(verify_prefix)
    return if strays.empty?

    # Never delete objects we can't name exactly — surface them for a human instead.
    Rails.logger.warn "[DELETE] Stray objects remain under #{verify_prefix}: #{strays.join(',')}"
    Sentry.capture_message(
      "Stray objects remain under deleted catalog prefix #{verify_prefix}",
      level: :warning,
      extra: { stray_count: strays.size, stray_keys: strays }
    )
  end
end
