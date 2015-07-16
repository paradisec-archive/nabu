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
      unless File.file? file_path
        @ilist.write(file_path) { self.quality = quality }

        file_path
      end
    else
      @ilist.to_a.map.with_index do |image, i|
        page_file_path = file_path.sub(".#{format}", "#{multipart ? "-page#{i+1}" : ''}.#{format}")
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
        new_suffix = "#{multipart ? "-page#{i+1}" : ''}#{size ? "-thumb-#{ADMIN_MASK}" : ''}.#{format}"
        file_path = "#{@file.sub(".#{extension}", new_suffix)}"

        unless File.file? file_path
          outfile = image.resize_to_fit(size, size)
          outfile.write(file_path) { self.quality = 50 }
        end
      end
    end
  end
end