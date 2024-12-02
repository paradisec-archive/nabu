require 'csv'
require 'aws-sdk-s3'

# NOTE: We use this service for random oneoff scripts we need over time
class JunkService
  attr_reader :catalog_dir, :verbose

  def initialize(env, verbose: false)
  end

  def run
    filenames = Essence.pluck(:id, :filename)
    filenames_hash = {}

    filenames.each do |id, filename|
      item_name, extension = filename.split('.', 2)
      filenames_hash[item_name] ||= { extensions: [], errors: [] }
      filenames_hash[item_name][:extensions] << extension.downcase
    end

    ext_map = {
      audio_ok: [
       'mp3',
       'wav'
      ],
       audio: [
       'mpg'
      ],
      video_ok: [
        'mp4',
        'mxf',
        'mkv'
      ],
      video: [
        'dv',
        'mov',
        'webm',
        'm4v',
        'avi',
        'mts'
      ],
      image_ok: [
        'jpg',
        'tif'
      ],
      image: [
        'png'
      ],
      lang: [
        'eaf',
        'trs',
        'xml',
        'cha',
        'fwbackup',
        'pfsx',
        'ixt',
        'cmdi',
        'lbl',
        'textgrid',
        'srt',
        'flextext',
        'tex',
        'imdi',
        'version',
        'annis',
        'opex'
      ],
      standalone: [
        'txt',
        'pdf',
        'rtf',
        'xlsx',
        'docx',
        'img',
        'tab',
        'odt',
        'html',
        'csv',
        'ods',
        'kml',
        'zip'
      ],
      broken: [
        'mov.eaf',
        'eopas1.ixt',
        'eopas2.ixt',
        'mp4_good_audio.mp3',
        'mp4_good_audio.mp4',
        'mp4_good_audio.mxf',
        'mp4_good_audio.wav',
        'masing.pdf',
        'masing.rtf',
        'masing.txt',
        '5.mp3',
        '5.wav',
        'txt.txt',
        'wav.eaf',
        'wav.mp3',
        'wav.wav'
      ]
    }

    filenames_hash.each do |item_name, data|
      filenames_hash[item_name][:extensions] = data[:extensions].sort
    end

    filenames_hash.each do |item_name, data|
      extensions = data[:extensions].clone

      # Audio
      if extensions.include?('mp3') && !extensions.include?('wav')
        data[:errors] << '+MP3-WAV'
      end
      if extensions.include?('wav') && !extensions.include?('mp3')
        data[:errors] << '+WAV-MP3'
      end
      extensions = extensions - ext_map[:audio_ok]
      if (extensions & ext_map[:audio]).any?
        data[:errors] << '+AUDIO'
      end
      extensions = extensions - ext_map[:audio]

      # Normal Paragest Video (plus old video)
      if extensions.include?('mkv') && !extensions.include?('mp4')
        data[:errors] << '+MKV-MP4'
      end
      if extensions.include?('mxf') && !extensions.include?('mp4')
        data[:errors] << '+MXF-MP4'
      end
      if extensions.include?('mp4') && !(extensions.include?('mkv') || extensions.include?('mxf'))
        data[:errors] << '+MP4-MKV'
      end
      extensions = extensions - ext_map[:video_ok]
      if (extensions & ext_map[:video]).any?
        data[:errors] << '+VIDEO'
      end
      extensions = extensions - ext_map[:video]

      # Image
      if extensions.include?('jpg') && !extensions.include?('tif')
        data[:errors] << '+JPG-TIF'
      end
      if extensions.include?('tif') && !extensions.include?('jpg')
        data[:errors] << '+TIF-JPG'
      end
      extensions = extensions - ext_map[:image_ok]
      if (extensions & ext_map[:image]).any?
        data[:errors] << '+IMAGE'
      end
      extensions = extensions - ext_map[:image]

      extensions = extensions - ext_map[:lang]
      extensions = extensions - ext_map[:standalone]
      if (extensions & ext_map[:broken]).any?
        data[:errors] << '+BROKEN'
      end
      extensions = extensions - ext_map[:broken]


      if extensions.any?
        abort "Item: #{item_name}, Extensions: #{extensions.join(', ')}"
      end
    end

    puts '# Error Summary'
    filenames_hash.each do |item_name, data|
      next if data[:errors].empty?

      puts "Item: #{item_name}, Extensions: #{data[:extensions].join(', ')}, Errors: #{data[:errors].join(', ')}"
    end
  end
end
