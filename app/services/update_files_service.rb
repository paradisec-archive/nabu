# Service to implement the archive:update_files task
# FIXME: Uses the globally defined methods `directories`, `parse_file_name`, `import_metadata`, and `generate_derived_files` from archive.rake.
class UpdateFilesService
  def self.run(archive, ignore_update_file_prefixes, force_update, verbose)
    update_files_service = new(archive, ignore_update_file_prefixes, force_update, verbose)
    update_files_service.run
  end

  def initialize(archive, ignore_update_file_prefixes, force_update, verbose)
    @archive = archive
    @ignore_update_file_prefixes = ignore_update_file_prefixes
    @force_update = force_update
    @verbose = verbose
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
      dir_contents = Dir.entries(directory)
      dir_contents.each do |file|
        next unless File.file? "#{directory}/#{file}"
        puts "---------------------------------------------------------------" if @verbose
        puts "Inspecting file #{file}..."
        basename, extension, coll_id, item_id, collection, item = parse_file_name(file)
        unless collection && item
          puts "ERROR: skipping file #{file} - does not relate to an item #{coll_id}-#{item_id}"
          next
        end

        # skip PDSC_ADMIN and rename CAT & df files
        next if basename.split('-').last == "PDSC_ADMIN"
        if basename.split('-').last == "CAT" || basename.split('-').last == "df"
          FileUtils.mv(directory + "/" + file, directory + "/" + basename + "-PDSC_ADMIN." + extension)
          next
        end

        if @ignore_update_file_prefixes.any? {|prefix| basename.start_with?(prefix) }
          puts "ERROR: file #{file} skipped - suspected of being crash-prone"
          next
        end

        # extract media metadata from file
        begin
          import_metadata(directory, file, item, extension, @force_update)
        rescue => e
          puts "ERROR: file #{file} skipped - error importing metadata [#{e.message}]" if @verbose
          puts " >> #{e.backtrace}"
          next
        end

        # REVIEW: Can this code throw an exception?
        full_file_path = directory + "/" + file
        essence = Essence.where(:item_id => item, :filename => file).first
        media = Nabu::Media.new full_file_path
        generate_derived_files(full_file_path, item, essence, extension, media)
      end
    end
    puts "===" if @verbose
    puts "Update Files finished." if @verbose
    puts "===" if @verbose
  end
end
