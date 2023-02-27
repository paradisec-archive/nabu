# Batch transcoding of essence files
class BatchTranscodeEssenceFileService
  def self.run(batch_size, dry_run)
    batch_transcode_essence_file_service = new(batch_size, dry_run)
    batch_transcode_essence_file_service.run
  end

  def initialize(batch_size, dry_run)
    @batch_size = batch_size
    @dry_run = dry_run
    @essence_transcode_count = 0
  end

  def run
    Item.find_each do |item|
      break if @essence_transcode_count >= @batch_size
      process_item(item)
    end
  end

  def process_item(item)
    transcode_essence_file_service = TranscodeEssenceFileService.new(item)
    if @dry_run
      puts "Would transcode #{item.id}"
    else
      transcode_essence_file_service.run
      @essence_transcode_count += transcode_essence_file_service.essence_transcode_count
    end
  end
end
