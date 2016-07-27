# Service to implement the archive:admin_files task
# FIXME: Uses the globally defined method `directories` from archive.rake, and ItemOfflineTemplate.
class AdminFilesService
  def self.run(verbose, archive)
    admin_files_service = new(verbose, archive)
    admin_files_service.run
  end

  def initialize(verbose, archive)
    @verbose = verbose
    @archive = archive
  end

  def run
    # get all subdirectories in archive
    puts "---------------------------------------------------------------"
    puts "Gathering all subdirectories in the archive..."
    subdirs = directories(@archive)
    puts "...done"

    # extract metadata from each essence file in each directory
    subdirs.each do |directory|
      puts "===" if @verbose
      puts "---------------------------------------------------------------" if @verbose
      puts "Working through directory #{directory}" if @verbose

      path, item_id = File.split(directory)
      _path, coll_id = File.split(path)

      puts "item #{coll_id}-#{item_id}"
      # force case sensitivity in MySQL - see https://dev.mysql.com/doc/refman/5.7/en/case-sensitivity.html
      collection = Collection.where('BINARY identifier = ?', coll_id).first
      next unless collection
      item = collection.items.where('BINARY identifier = ?', item_id).first
      next unless item

      file = directory + "/#{item.full_identifier}-CAT-PDSC_ADMIN.xml"

      next if File.exist?(file)

      template = ItemOfflineTemplate.new
      template.item = item
      data = template.render_to_string :template => "items/show.xml.haml"
      File.open(file, 'w') {|f| f.write(data)}
      puts "created #{file}"
    end
    puts "===" if @verbose
    puts "Check and create PDSC_ADMIN Files finished." if @verbose
    puts "===" if @verbose
  end
end
