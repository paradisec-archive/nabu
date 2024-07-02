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

    identifier = @data.full_identifier
    filename = 'pdsc_admin/ro-crate-metadata.json'

    Proxyist.upload_object identifier, filename, data, 'Content-Type' => 'application/json'
  end
end
