class ItemCatalogService
  def initialize(item)
    @item = item
  end

  # since rendering templates is a controller or view task, simply pass in the data you want
  # stored into the catalog file. this will probably be a render_to_string of the desired template
  def save_file(data)
    directory = Nabu::Application.config.archive_directory +
      "#{@item.collection.identifier}/#{@item.identifier}/"

    # create all directories in the hierarchy, if required
    FileUtils.mkdir_p(directory)

    # save file - use extended item template incl. collection details
    file = directory + "#{@item.full_identifier}-CAT-PDSC_ADMIN.xml"
    File.open(file, 'w') {|f| f.write(data)}
  end
end