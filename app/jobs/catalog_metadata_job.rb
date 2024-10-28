class CatalogMetadataJob < ApplicationJob
  queue_as :default

  def perform(data, is_item)
    local_data = { data:, is_item:, admin_rocrate: true }


    filename = 'ro-crate-metadata.json'

    if is_item
      rocrate = Api::V1::OniController.render :object_meta_item, assigns: local_data
      Nabu::Catalog.instance.upload_item_admin(data, filename, rocrate, 'application/json')
    else
      rocrate = Api::V1::OniController.render :object_meta_collection, assigns: local_data
      Nabu::Catalog.instance.upload_collection_admin(data, filename, rocrate, 'application/json')
    end
  end
end
