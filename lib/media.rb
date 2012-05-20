module Nabu
  class Media
    FM = FileMagic.mime
    def initialize(file)
      @file = file
      if ! File.exist? @file
        raise NotFound
      end
    end

    def mimetype
      @mimetype ||= FM.file @file, true
    end

    def size
      @size ||= File.size @file
    end

    def bitrate
      probe['bit_rate']
    end

    def samplerate
      probe['sample_rate']
    end

    def duration
      probe['duration']
    end

    def channels
      probe['channels']
    end

    def fps
      nu, de = probe['r_frame_rate'].split '/'
      if nu and de
        nu/de.to_f
      end
    end

    def summary
      puts "
      mimetype: #@mimetype
      size: #@size
      bitrate: #@bitrate bps
      samplerate: #@samplerate Hz
      duration: #@duration seconds
      channels #@channels channels
      fps: #@fps fps
      "
    end

    def probe
      return @data if @data
      output = %x{ffprobe -show_format -show_streams #{media_filename} 2> /dev/null}
      raise "Error running ffprobe, returned #{$?}" unless $?.success?

      data = {}
      output.lines.each do |line|
        line.chomp!
        next if line =~ /^\[/
        key, value = line.split(/=/)
        @data[key.strip] = value.strip
      end
      @data
    end
  end
end
