require 'nabu/media'

# Batch transformation of images.
# For an individual transformation, see ImageTransformerService.
class BatchImageTransformerService
  def self.run(batch_size, verbose)
    batch_image_transformer_service = new(batch_size, verbose)
    batch_image_transformer_service.run
  end

  def initialize(batch_size, verbose)
    @batch_size = batch_size
    @image_files = find_image_files
    @verbose = verbose
  end

  def find_image_files
    Essence.includes(item: [:collection]).where(derived_files_generated: false).where('mimetype like ?', 'image/%').limit(@batch_size)
  end

  def run
    @image_files.each do |image_file|
      next unless File.file?(image_file.path)
      item = image_file.item
      file = image_file.path
      extension = File.extname(file)
      begin
        media = Nabu::Media.new image_file.path
        image_transformer = ImageTransformerService.new(media, file, item, image_file, extension)
        image_transformer.perform_conversions
      rescue => e
        puts "WARNING: file #{file} skipped - error transforming image [#{e.message}]" if @verbose
        puts " >> #{e.backtrace}"
        next
      end
    end
  end
end
