require 'RMagick'

class ImageTransformerService
  include Magick

  attr_accessor :multipart

  ADMIN_MASK = 'PDSC_ADMIN'

  def initialize(media, file, force_generation = false)
    @media = media
    @file = file
    @type = media.mimetype == 'image/tiff' ? :tiff : :other
    @ilist = ImageList.new(@file)
    @multipart = @ilist.length > 1
    @force_generation = force_generation
  end

  def convert_to(format, extension, quality = 50)
    file_path = @file.sub(".#{extension}", ".#{format}")

    if [:pdf, :tif].include?(format)
      @ilist.write(file_path) { self.quality = quality }
      file_path
    else
      @ilist.to_a.map.with_index do |image, i|
        page_file_path = file_path.sub(".#{format}", "#{multipart ? "-page#{i+1}" : ''}.#{format}")
        image.write(page_file_path) { self.quality = quality }

        page_file_path
      end
    end
  end

  def generate_thumbnails(extension, sizes = [144], format = :jpg)
    @ilist.to_a.each_with_index do |image, i|
      sizes.each do |size|
        new_suffix = "#{multipart ? "-page#{i+1}" : ''}#{size ? "-thumb-#{ADMIN_MASK}" : ''}.#{format}"
        file_path = "#{@file.sub(".#{extension}", new_suffix)}"

        outfile = image.resize_to_fit(size, size)
        outfile.write(file_path) { self.quality = 50 }
      end
    end
  end

=begin
  # separated write from convert to allow for in-memory usage of converted images
  def write(data, extension, format, thumb_size = nil)
    root_file_path = @file.sub(".#{extension}", '')

    if [:pdf, :tif].include?(format)
      #if producing a multi-page format, just dump it all in
      file_path = "#{root_file_path}.#{format}"

      # this could theoretically be done using the original @ilist files, but using the converted jpegs
      # produces a file 1/30 of the size
      images = ImageList.new
      Array(data).each do |datum|
        images.from_blob datum
      end

      puts "Writing combined multipart file to #{file_path}"

      images.write file_path

      File.basename file_path
    else
      #otherwise create multiple files
      Array(data).map.with_index do |datum, i|
        file_path = "#{root_file_path}-page#{i+1}" if @multipart && thumb_size.nil? #don't add pages for thumbs
        # In order to allow for multiple thumbnail sizes, add something along the lines of:
        # -#{thumb_size}x#{thumb_size}
        # to the new_suffix that will identify the dimensions of the thumb
        # NOTE: this was removed to enable the PDSC viewer to easily construct the filename and not guess sizes
        new_suffix = "#{thumb_size ? "-thumb-#{ADMIN_MASK}" : ''}.#{format}"
        file_path = "#{file_path || root_file_path}#{new_suffix}"

        puts "Writing #{thumb_size.nil? ? 'image' : 'thumb'} to #{file_path}"

        File.open(file_path, 'wb') do |f|
          f.write datum
        end

        File.basename file_path
      end
    end
  end
=end

  # these helpers are used to determine which files have already been generated, so as to not override them
  def path_to_file_as(format, thumb = false, pages = false)
    extension = @file.split('.').last
    @file.sub(".#{extension}", "#{pages ? '-page1' : ''}#{thumb ? "-thumb-#{ADMIN_MASK}" : ''}.#{format}")
  end

  def file_exists_as(format, thumb = false)
    return @force_generation if @force_generation
    File.file?(path_to_file_as(format, thumb)) || File.file?(path_to_file_as(format, thumb, true))
  end
end