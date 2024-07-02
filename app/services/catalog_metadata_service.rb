class CatalogMetadataService
  def initialize(item)
    @item = item
    @template = OfflineController.new
  end

  def save_file
    data = @template.render_to_string template: 'items/catalog_export', formats: [:xml], handlers: [:haml], locals: { item: @item }

    identifier = @item.full_identifier
    filename = "#{@item.full_identifier}-CAT-PDSC_ADMIN.xml"

    Proxyist.upload_object identifier, filename, data, 'Content-Type' => 'text/xml'
  end
end
