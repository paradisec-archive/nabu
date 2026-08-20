class CatalogMetadataJob < ApplicationJob
  queue_as :default

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
