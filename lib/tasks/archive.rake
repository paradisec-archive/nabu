require 'media'

namespace :archive do

  desc 'Provide essence files in scan_directory with metadata for sealing'
  task :export_metadata => :environment do
    # find essence files in Nabu::Application.config.scan_directory
    dir_contents = Dir.entries(Nabu::Application.config.scan_directory)
    dir_contents -= [".", ".."]

    # for each essence file, find its collection & item
    # by matching the pattern
    # "#{collection_id}-#{item_id}-xxx.xxx"
    dir_contents.each do |file|
      coll_id, item_id = file.split('-')
      extension = file.split('.').last
      basename = File.basename(file, "." + extension)

      collection = Collection.find_by_identifier coll_id
      if !collection
        puts "ERROR: could not find collection id=#{coll_id} for file #{file} - skipping"
        next
      end
      item = collection.items.find_by_identifier item_id
      if !item
        puts "ERROR: could not find item pid=#{coll_id}-#{item_id} for file #{file} - skipping"
        next
      end

      # check if the item's "metadata ready for export" flag is set
      # raise a warning if not and skip file
      if !item.metadata_exportable
        puts "ERROR: metadata of item pid=#{coll_id}-#{item_id} is not complete for file #{file} - skipping"
        next
      end

      # write the appropriate metadata file
      metadata_filename = Nabu::Application.config.scan_directory + basename
      case (extension)
      # .wav -> .imp.xml
      when ("wav")
        data = HTTParty.get("http://localhost:3000/items/#{item.id}.xml?xml_type=imp").body
        p data
#        s = item.to_xml(:params => {:xml_type => 'imp'})

        metadata_filename += ".imp.xml"
        metadata_file = File.open(metadata_filename, 'w') {|f| f.write(data)}
      # .mp3 -> .id3.xml
      when ("mp3")
      # .ogg -> .vorbiscomment (TODO)
      else
        puts "WARNING: don't know what metadata file to create for #{file} of type #{extension} - skipping"
        next
      end
      puts "SUCCESS: metadata file #{metadata_filename} created for #{file}"
    end
  end


  desc 'Import files into the archive'
  task :import_files => :environment do
    # find essence files in Nabu::Application.config.upload_directory
    dir_contents = Dir.entries(Nabu::Application.config.upload_directory)
    dir_contents -= [".", ".."]

    # make sure the archive directory exists and all its parent directories
    FileUtils.mkdir_p(Nabu::Application.config.archive_directory)

    # for each essence file, find its collection & item
    # by matching the pattern
    # "#{collection_id}-#{item_id}-xxx.xxx"
    dir_contents.each do |file|
      coll_id, item_id = file.split('-')
      extension = file.split('.').last
      basename = File.basename(file, "." + extension)

      collection = Collection.find_by_identifier coll_id
      if !collection
        puts "ERROR: could not find collection id=#{coll_id} for file #{file} - skipping"
        next
      end
      item = collection.items.find_by_identifier item_id
      if !item
        puts "ERROR: could not find item pid=#{coll_id}-#{item_id} for file #{file} - skipping"
        next
      end

      # make sure the archive directory for the collection and item exists
      # and move the file there
      destination_path = Nabu::Application.config.archive_directory + "#{coll_id}/#{item_id}/"
      FileUtils.mkdir_p(destination_path)
      FileUtils.mv(Nabu::Application.config.upload_directory + file, destination_path + file)

      puts "---------------------------------------------------------------"
      puts "SUCCESS: file #{file} copied into archive at #{destination_path}"

      # files of the pattern "#{collection_id}-#{item_id}-xxx-PDS_ADMIN.xxx"
      # will be copied, but not added to the list of imported files in Nabu.
      next if basename.split('-').last == "PDS_ADMIN"

      # extract media metadata from file
      media = Nabu::Media.new destination_path + file
      if !media
        puts "ERROR: was not able to parse #{file} of type #{extension} - skipping"
        next
      end

      # find essence file in Nabu DB; if there is none, create a new one
      essence = Essence.where(:item_id => item, :filename => file).first
      if !essence
        essence = Essence.new(:item => item,:filename => file)
      end

      # update essence entry with metadata from file
      essence.mimetype   = media.mimetype
      essence.size       = media.size
      essence.bitrate    = media.bitrate
      essence.samplerate = media.samplerate
      essence.duration   = media.duration
      essence.channels   = media.channels
      essence.fps        = media.fps
      if !essence.valid?
        puts "ERROR: invalid metadata for #{file} of type #{extension} - skipping"
        essence.errors.each {|field, msg| puts "#{field}: #{msg}"}
        next
      end
      essence.save!

      puts "SUCCESS: file #{file} metadata imported into Nabu"
    end
  end

end
