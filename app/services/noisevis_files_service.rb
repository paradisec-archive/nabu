# Service to implement the archive:noisevis_files task
class NoisevisFilesService
  def self.run(archive, verbose)
    noisevis_files_service = new(archive, verbose)
    noisevis_files_service.run
  end

  def initialize(archive, verbose)
    @archive = archive
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
        # REVIEW: wav or mp3?
        basename, extension, coll_id, item_id, collection, item = parse_file_name(file, "wav")
        unless collection && item
          # No need to log a failure message, as parse_file_name does that.
          next
        end

        # WIP: Rest of service.
      end
    end
    puts "===" if @verbose
    puts "Update Files finished." if @verbose
    puts "===" if @verbose
  end
end
