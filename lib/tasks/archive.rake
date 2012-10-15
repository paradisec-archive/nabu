require 'media'

class OfflineTemplate < AbstractController::Base
  include AbstractController::Rendering
  include AbstractController::Helpers
  #include AbstractController::Layouts
  include CanCan::ControllerAdditions

  def initialize(*args)
    super()
    lookup_context.view_paths = Rails.root.join('app', 'views')
  end

  def current_user
    @current_user ||= User.admins.first
  end

  #def params
  #  {}
  #end
end

class ItemOfflineTemplate < OfflineTemplate
  attr_accessor :item
end

namespace :archive do

  desc 'Provide essence files in scan_directory with metadata for sealing'
  task :export_metadata => :environment do
    # scan for WAV files .wav and create .imp.xml & id3.xml
    dir_contents = Dir.entries(Nabu::Application.config.scan_directory)

    # for each essence file, find its collection & item
    # by matching the pattern
    # "#{collection_id}-#{item_id}-xxx.xxx"
    dir_contents.each do |file|
      next unless File.file? "#{Nabu::Application.config.scan_directory}/#{file}"
      basename, extension, coll_id, item_id, collection, item = parse_file_name(file, 'wav')
      next if !collection || !item

      # if metadata files exist, skip to the next file
      metadata_filename_imp = Nabu::Application.config.write_imp + basename + ".imp.xml"
      metadata_filename_id3 = Nabu::Application.config.write_id3 + basename + ".id3.v2_3.xml"
      next if (File.file? "#{metadata_filename_imp}") && (File.file? "#{metadata_filename_id3}")

      # check if the item's "metadata ready for export" flag is set
      # raise a warning if not and skip file
      if !item.metadata_exportable
        puts "ERROR: metadata of item pid=#{coll_id}-#{item_id} is not complete for file #{file} - skipping"
        next
      end

      template = ItemOfflineTemplate.new
      template.item = item
      data_imp = template.render_to_string :template => "items/show.imp.xml"
      data_id3 = template.render_to_string :template => "items/show.id3.xml"

      File.open(metadata_filename_imp, 'w') {|f| f.write(data_imp)}
      File.open(metadata_filename_id3, 'w') {|f| f.write(data_id3)}
      puts "SUCCESS: metadata files\n #{metadata_filename_imp},\n #{metadata_filename_id3}\n created for #{file}"
    end
  end


  desc 'Import files into the archive'
  task :import_files => :environment do
    # find essence files in Nabu::Application.config.upload_directories
    dir_list = Nabu::Application.config.upload_directories

    dir_list.each do |upload_directory|
      next unless File.directory?(upload_directory)
      dir_contents = Dir.entries(upload_directory)

      # for each essence file, find its collection & item
      # by matching the pattern
      # "#{collection_id}-#{item_id}-xxx.xxx"
      dir_contents.each do |file|
        next unless File.file? "#{upload_directory}/#{file}"

        # skip files of size 0 bytes
        if !File.size?("#{upload_directory}/#{file}")
          puts "WARNING: file #{file} skipped, since it is empty"
          next
        end

        basename, extension, coll_id, item_id, collection, item = parse_file_name(file)
        next if !collection || !item
        puts "---------------------------------------------------------------"

        # make sure the archive directory for the collection and item exists
        # and move the file there
        destination_path = Nabu::Application.config.archive_directory + "#{coll_id}/#{item_id}/"
        FileUtils.mkdir_p(destination_path)
        FileUtils.mv(upload_directory + file, destination_path + file)

        puts "SUCCESS: file #{file} copied into archive at #{destination_path}"

        # move old style CAT and df files to the new naming scheme
        if basename.split('-').last == "CAT" || basename.split('-').last == "df"
          FileUtils.mv(destination_path + file, destination_path + "/" + basename + "-PDSC_ADMIN." + extension)
        end

        # files of the pattern "#{collection_id}-#{item_id}-xxx-PDSC_ADMIN.xxx"
        # will be copied, but not added to the list of imported files in Nabu.
        next if basename.split('-').last == "PDSC_ADMIN"

        # extract media metadata from file
        puts "Inspecting file #{file}..."
        import_metadata(destination_path, file, item, extension)
        puts "...done"
      end
    end
  end

  desc 'Update essence metadata of existing files in the archive'
  task :update_files => :environment do
    # find essence files in Nabu::Application.config.archive_directory
    archive = Nabu::Application.config.archive_directory

    # remove all current information about essences in DB
    # comment this out after the seeding
    puts "---------------------------------------------------------------"
    puts "Deleting all existing essence information in Nabu..."
    Essence.delete_all
    puts "...done"

    # get all subdirectories in archive
    puts "---------------------------------------------------------------"
    puts "Gathering all subdirectories in the archive..."
    subdirs = directories(archive)
    puts "...done"

    # extract metadata from each essence file in each directory
    subdirs.each do |directory|
      puts "==="
      puts "---------------------------------------------------------------"
      puts "Working through directory #{directory}"
      dir_contents = Dir.entries(directory)
      dir_contents.each do |file|
        next unless File.file? "#{directory}/#{file}"
        puts "---------------------------------------------------------------"
        puts "Inspecting file #{file}..."
        puts "---------------------------------------------------------------"
        puts "Inspecting file #{directory}/#{file}..."
        basename, extension, coll_id, item_id, collection, item = parse_file_name(file)
        next if !collection || !item

        # skip PDSC_ADMIN and rename CAT & df files
        next if basename.split('-').last == "PDSC_ADMIN"
        if basename.split('-').last == "CAT" || basename.split('-').last == "df"
          FileUtils.mv(directory + "/" + file, directory + "/" + basename + "-PDSC_ADMIN." + extension)
          next
        end

        # extract media metadata from file
        import_metadata(directory, file, item, extension)
      end
    end
    puts "==="
    puts "Update Files finished."
    puts "==="
  end


  # HELPERS

  def directories(path)
    data = []
    Dir.foreach(path) do |entry|
      next if (entry == '..' || entry == '.' || entry == '.snapshot' || entry == '.server_backups')
      full_path = File.join(path, entry)
      if File.directory?(full_path)
        data << full_path
        data += directories(full_path)
      end
    end
    return data
  end


  def parse_file_name(file, file_extension=nil)
    coll_id, item_id = file.split('-')
    return unless item_id

    extension = file.split('.').last
    return if file_extension && file_extension != extension
    basename = File.basename(file, "." + extension)

    collection = Collection.find_by_identifier coll_id
    if !collection
      puts "ERROR: could not find collection id=#{coll_id} for file #{file} - skipping"
      return
    end
    item = collection.items.find_by_identifier item_id
    if !item
      puts "ERROR: could not find item pid=#{coll_id}-#{item_id} for file #{file} - skipping"
      return
    end
    [basename, extension, coll_id, item_id, collection, item]
  end


  def import_metadata(path, file, item, extension)
    # extract media metadata from file
    media = Nabu::Media.new path + "/" + file
    if !media
      puts "ERROR: was not able to parse #{path + "/" + file} of type #{extension} - skipping"
      return
    end

    # find essence file in Nabu DB; if there is none, create a new one
    essence = Essence.where(:item_id => item, :filename => file).first
    if !essence
      essence = Essence.new(:item => item, :filename => file)
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
      return
    end
    essence.save!

    puts "SUCCESS: file #{file} metadata imported into Nabu"
  end
end
