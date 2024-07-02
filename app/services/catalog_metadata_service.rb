class CatalogMetadataService
  def initialize(data, is_item)
    @data = data
    @is_item = is_item
  end

  def save_file
    local_data = {
      data: @data,
      is_item: @is_item,
      admin_rocrate: true
    }
    data = Api::V1::OniController.render :object_meta, assigns: local_data

    filename = 'ro-crate-metadata.json'

    if @is_item
      Nabu::Catalog.instance.upload_item_admin(@data, filename, data, 'application/json')
    else
      Nabu::Catalog.instance.upload_collection_admin(@data, filename, data, 'application/json')
    end
  end
end
