require 'nabu/media'

# TODO: Temp till paragest
def essence_path(essence)
  "/src/catalog/#{essence.full_identifier}"
end

# Transcode essence files for a single item
class TranscodeEssenceFileService
  include ActionView::Helpers::NumberHelper

  attr_reader :essence_transcode_count

  def self.run(item)
    transcode_essence_file_service = new(item)
    transcode_essence_file_service.run
  end

  def initialize(item)
    @item = item
    @essence_transcode_count = 0
  end

  def run
    return unless @item.essences.where("mimetype like 'video/%'").any?

    transcode_essences_to_video_webm
  end

  def transcode_essences_to_video_webm
    @item.essences.where("mimetype like 'video/%'").each do |essence|
      case essence.mimetype
      when 'video/mp4', 'video/mpeg', 'video/quicktime', 'video/x-dv', 'video/x-msvideo'
        transcode_to_video_webm(essence)
      end
    end
  end

  def transcode_to_video_webm(essence)
    new_essence_filename = File.basename(essence.filename, '.*') + '.webm'
    return if @item.essences.where(filename: new_essence_filename).any?
    new_essence = Essence.new(:item => @item, :filename => new_essence_filename)
    return unless File.exist?(essence_path(essence))
    movie = FFMPEG::Movie.new(essence_path(essence))
    movie.transcode(essence_path(essence), '-c:v libvpx -qmin 0 -qmax 20 -crf 5 -b:v 2M -c:a libvorbis')
    populate_essence_object(new_essence)
  end

  def populate_essence_object(essence)
    media = Nabu::Media.new(essence_path(essence))
    fail unless media

    essence.mimetype   = media.mimetype
    essence.size       = media.size
    essence.bitrate    = media.bitrate
    essence.samplerate = media.samplerate
    essence.duration   = number_with_precision(media.duration, :precision => 3)
    essence.channels   = media.channels
    essence.fps        = media.fps

    fail unless essence.valid?
    essence.save!
    @essence_transcode_count += 1
  end
end
