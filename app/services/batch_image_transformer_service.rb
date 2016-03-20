require 'media'

# Batch transformation of images.
# For an individual transformation, see ImageTransformerService.
class BatchImageTransformerService
  def self.run(batch_size)
    batch_image_transformer_service = new(batch_size)
    batch_image_transformer_service.run
  end

  def initialize(batch_size)
    @batch_size = batch_size
    @image_files = find_image_files
  end

  def find_image_files
    Essence.includes(item: [:collection]).where(derived_files_generated: false).where('mimetype like ?', 'image/%').limit(@batch_size)
  end

  def run
    @image_files.each do |image_file|
      media = Nabu::Media.new image_file.path
      item = image_file.item
      file = image_file.path
      extension = 'jpg'
      image_transformer = ImageTransformerService.new(media, file, item, image_file, extension)
      image_transformer.perform_conversions
    end
  end
end
