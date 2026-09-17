class CatalogMetadataJob < ApplicationJob
  queue_as :default

  # An item's crate is regenerated every time an essence is added, so ingesting a nine file item
  # rewrote its ro-crate eight times in two minutes. Each rewrite is an S3 object creation, and each
  # of those starts a Fargate job to back the same file up again. Waiting until the burst has passed
  # means these all render the same crate, and the upload skips the ones that would change nothing.
  DEBOUNCE_WINDOW = 5.minutes

  def self.enqueue_debounced(record, is_item)
    set(wait: DEBOUNCE_WINDOW).perform_later(record, is_item)
  end

  def perform(data, is_item)
    local_data = { data:, admin_ro_crate: true }


    filename = Nabu::Catalog::ADMIN_RO_CRATE_FILENAME

    if is_item
      ro_crate = Api::V1::OniController.render :object_meta_item, assigns: local_data
      Nabu::Catalog.instance.upload_item_admin(data, filename, ro_crate, 'application/json')
    else
      ro_crate = Api::V1::OniController.render :object_meta_collection, assigns: local_data
      Nabu::Catalog.instance.upload_collection_admin(data, filename, ro_crate, 'application/json')
    end
  end
end
