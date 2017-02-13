class ItemCatalogService
  def initialize(item)
    @item = item
    @template = OfflineController.new
  end

  def save_file
    data = @template.render_to_string template: 'items/catalog_export', formats: [:xml], handlers: [:haml], locals: {item: @item}

    directory = Nabu::Application.config.archive_directory +
      "#{@item.collection.identifier}/#{@item.identifier}/"

    # create all directories in the hierarchy, if required
    FileUtils.mkdir_p(directory)

    # save file - use extended item template incl. collection details
    file = directory + "#{@item.full_identifier}-CAT-PDSC_ADMIN.xml"
    File.open(file, 'w') {|f| f.write(data)}
  end
end