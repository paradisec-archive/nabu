class CatalogDbSyncValidatorService
  # TODO: Make this support proxyist

  attr_reader :catalog_dir, :verbose

  def initialize(verbose: false)
    @catalog_dir = '/srv/catalog'
    @verbose = verbose
  end

  def run
    process_collections
  end

  private

  def process_items(collection, db_items)
    item_ids(collection.identifier).each do |item_id|
      item = db_items.find { |i| i.identifier == item_id }
      unless item
        # FIXME: Put this back
        # puts "WARNING: ITEM LEVEL: #{collection.identifier}/#{item_id} does not exist in the database"
        next
      end

      db_essences = item.essences.to_a.each { | essence | essence.filename = essence.filename.downcase }
      process_essences(collection, item, db_essences)
    end
  end

  def process_essences(collection, item, db_essences)
    essences = essence_ids(collection.identifier, item.identifier)
    files = essences.map { |essence| essence.sub(/\.*[a-zA-Z0-9]+$/, '') }.uniq

    essences.each do |essence_id|
      next if essence_id =~ /#{collection.identifier}-#{item.identifier}-(CAT|LIST|df|df_revised|df_ammended)-PDSC_ADMIN.(xml|pdf|html|html|rtf)/

      if essence_id =~ /PDSC_ADMIN/
        fileprefix = essence_id.sub(/-(spectrum|thumb|checksum|soundimage|preview|sjo01df|ind01df|asfdf|mwfdf|amhdf|ban01df|ropdf|jpn04df|jpn02df|tcidf|mjkdf|jpndf|kac01df)-PDSC_ADMIN\.(jpg|json|txt|pdf|ogg|htm|jpgf.tif)$/, '')
        next if files.include?(fileprefix)

        puts "WARNING: ITEM LEVEL: #{collection.identifier}/#{item.identifier}/#{essence_id} is unknown PDSC_ADMIN file"
        next
      end

      essence = db_essences.find { |i| i.filename == essence_id.downcase }
      unless essence
        puts "WARNING: ITEM LEVEL: #{collection.identifier}/#{item.identifier}/#{essence_id} does not exist in the database"
        next
      end
    end
  end

  def process_collections
    collection_ids.each do |collection_id|
      puts "## #{collection_id}" if verbose

      collection = Collection.find_by(identifier: collection_id)
      unless collection
        puts "WARNING: COLLECTION LEVEL: #{collection_id} does not exist in the database"
        next
      end

      process_items(collection, collection.items.to_a)
    end
  end

  def essence_ids(collection_id, item_id)
    ids = []

    Dir.entries(File.join(catalog_dir, collection_id, item_id)).each do |dir|
      next if ['.', '..'].include?(dir)

      unless File.file?(File.join(catalog_dir, collection_id, item_id, dir))
        puts "WARNING: ITEM LEVEL: #{collection_id}/#{item_id}/#{dir} is not a file"
        next
      end

      ids << dir
    end

    ids
  end

  def item_ids(collection_id)
    ids = []

    Dir.entries(File.join(catalog_dir, collection_id)).each do |dir|
      next if ['.', '..'].include?(dir)

      unless File.directory?(File.join(catalog_dir, collection_id, dir))
        puts "WARNING: ITEM LEVEL: #{collection_id}/#{dir} is not a directory"
        next
      end

      ids << dir
    end

    ids
  end

  def collection_ids
    ids = []

    Dir.entries(catalog_dir).each do |dir|
      next if ['.', '..', '.afm', '0001-Backups', '0002-Migration'].include?(dir)

      unless File.directory?(File.join(catalog_dir, dir))
        puts "WARNING: COLLECTION LEVEL: #{dir} is not a directory"
        next
      end

      ids << dir
    end

    ids
  end
end
