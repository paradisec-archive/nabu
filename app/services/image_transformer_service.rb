require 'rmagick'

class ImageTransformerService
  include Magick

  ADMIN_MASK = 'PDSC_ADMIN'

  def initialize(media, file, item, essence, extension, thumbnail_sizes = [144])
    @mimetype = media.mimetype
    if @mimetype.start_with?('image')
      @file = file
      @image_list = ImageList.new(@file)
      @multipart = (@image_list.length > 1)
      @item = item
      @extension = extension
      @essence = essence
      @thumbnail_sizes = thumbnail_sizes
    end
  end

  def perform_conversions
    return unless @mimetype.start_with?('image')

    generated_essences = []

    # if the file is a tif, convert it to jpeg (with additional PDF if tif is multi-page)
    if @mimetype == 'image/tiff'
      convert_tif_to_jpg(generated_essences)
    end

    generate_thumbnails @extension, @thumbnail_sizes

    puts 'Store generated files as essences...'
    all_essences_saved = true
    generated_essences.each do |essence|
      unless essence.save
        puts "WARNING: Converted file [#{essence.filename}] failed to save due to the following errors:"
        essence.errors.each {|field, error| puts "  [#{field}] #{error}"}
        all_essences_saved = false
      end
    end

    # if we've successfully generated the derived files, set the flag - otherwise this file will be picked up again next run
    if all_essences_saved
      @essence.derived_files_generated = true
      @essence.save
    end
  end

  # converts the file into the specified format and returns its new path (or nil if it already existed)
  def convert_to(format, extension, quality = 50)
    return unless @mimetype.start_with?('image')

    if [:pdf, :tif].include?(format)
      # if converting between multi-page formats, simply use imagemagick
      file_path = create_file_path(extension, format)
      return if File.file? file_path #skip existing files

      @image_list.write(file_path) { self.quality = quality }

      file_path
    else
      # if converting from multi-page format to single page - generate separate files for each page in the new format
      @image_list.to_a.map.with_index do |image, i|
        page_file_path = create_file_path(extension, format, i+1)
        next if File.file? page_file_path #skip existing files

        image.write(page_file_path) { self.quality = quality }
        page_file_path
      end
    end
  end

  def generate_thumbnails(extension, sizes)
    return unless @mimetype.start_with?('image')

    puts "Generate #{'thumbnail'.pluralize(@ilist.length)}"
    # for each image, generate thumbnails of all sizes
    @image_list.to_a.each_with_index do |image, i|
      sizes.each do |size|
        file_path = create_file_path(extension, :jpg, i+1, true)

        next if File.file? file_path #skip existing files

        outfile = image.resize_to_fit(size, size)
        outfile.write(file_path) { self.quality = 50 }
      end
    end
  end

  private

  #build an appropriate new file path based on pages, thumbnails and format where provided
  def create_file_path(extension, format, page_number = nil, is_thumbnail = false)
    new_suffix = ".#{format}"

    if is_thumbnail
      new_suffix = "-thumb-#{ADMIN_MASK}#{new_suffix}"
    end

    if @multipart && page_number.present?
      new_suffix = "-page#{page_number}#{new_suffix}"
    end

    @file.sub(".#{extension}", new_suffix)
  end

  def convert_tif_to_jpg(generated_essences)
    puts "Generate #{'JPG'.pluralize(@ilist.length)}"
    jpg_pages = convert_to :jpg, @extension

    jpg_pages.each do |page|
      next if page.nil? # if files already existed, there will be nils instead of filenames
      generated_essences << Essence.new(item: @item,
                                        filename: File.basename(page),
                                        mimetype: 'image/jpeg',
                                        size: File.size(page),
                                        derived_files_generated: true) #set 'generated already' flag so we don't get recursive
    end

    if @multipart
      generate_pdf(generated_essences)
    end
  end

  def generate_pdf(generated_essences)
    puts 'Generate PDF collection for pages'

    #if the input is multipart, also produce a pdf version of the whole thing
    pdf_file = convert_to :pdf, @extension
    if pdf_file.present? # if the PDF was newly generated, add it as an essence
      generated_essences << Essence.new(item: @item,
                                        filename: File.basename(pdf_file),
                                        mimetype: 'application/pdf',
                                        size: File.size(pdf_file))
    end
  end
end