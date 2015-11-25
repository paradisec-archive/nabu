require 'rmagick'

class ImageTransformerService
  include Magick

  ADMIN_MASK = 'PDSC_ADMIN'

  def initialize(media, file, item, essence, extension)
    @media = media
    @file = file
    @type = media.mimetype == 'image/tiff' ? :tiff : :other
    @ilist = ImageList.new(@file)
    @multipart = @ilist.length > 1
    @item = item
    @extension = extension
    @essence = essence
  end

  def perform_conversions
    if @media.mimetype.start_with?('image')
      generated_essences = []

      # if the file is a tif, convert it to jpeg
      if @media.mimetype == 'image/tiff'
        puts "Generate JPG#{@multipart ? 's' : ''}"
        converted = convert_to :jpg, @extension

        converted.each do |out|
          next if out.nil? # if files already existed, there will be nils instead of filenames
          generated_essences << Essence.new(item: @item, filename: File.basename(out), mimetype: 'image/jpeg', size: File.size(out))
        end

        if @multipart
          puts 'Generate PDF collection for pages'

          #if the input is multipart, also produce a pdf version of the whole thing
          multipart_file = convert_to :pdf, @extension
          if multipart_file.present? # if the file didn't already exist
            generated_essences << Essence.new(item: @item, filename: File.basename(multipart_file), mimetype: 'application/pdf',
                                              size: File.size(multipart_file))
          end
        end
      end

      #by default, this just generates a single thumbnail, but you can specify a comma-sep list of sizes
      # e.g. rake archive:import_files thumbnail_sizes='144,288,999'
      puts "Generate thumbnails#{@multipart ? 's' : ''}"
      if ENV['thumbnail_sizes']
        generate_thumbnails @extension, ENV['thumbnail_sizes'].split(',').map(&:strip)
      else
        generate_thumbnails @extension
      end

      generated_essences.each do |generated|
        if generated.valid?
          generated.save!
        else
          puts "ERROR: invalid metadata for #{@file} of type #{@extension} - skipping"
          generated.errors.each {|field, msg| puts "#{field}: #{msg}"}
          return false
        end
      end
    end

    # if we've successfully generated the derived files, set the flag
    @essence.derived_files_generated = true
    @essence.save

    true
  end

  def convert_to(format, extension, quality = 50)
    file_path = @file.sub(".#{extension}", ".#{format}")

    if [:pdf, :tif].include?(format)
      unless File.file? file_path
        @ilist.write(file_path) { self.quality = quality }

        file_path
      end
    else
      @ilist.to_a.map.with_index do |image, i|
        page_file_path = file_path.sub(".#{format}", "#{@multipart ? "-page#{i+1}" : ''}.#{format}")
        unless File.file? page_file_path
          image.write(page_file_path) { self.quality = quality }
          page_file_path
        end
      end
    end
  end

  def generate_thumbnails(extension, sizes = [144], format = :jpg)
    @ilist.to_a.each_with_index do |image, i|
      sizes.each do |size|
        new_suffix = "#{@multipart ? "-page#{i+1}" : ''}#{size ? "-thumb-#{ADMIN_MASK}" : ''}.#{format}"
        file_path = "#{@file.sub(".#{extension}", new_suffix)}"

        unless File.file? file_path
          outfile = image.resize_to_fit(size, size)
          outfile.write(file_path) { self.quality = 50 }
        end
      end
    end
  end
end