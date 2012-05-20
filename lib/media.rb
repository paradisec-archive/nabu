require 'filemagic'
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
      probe[:format]['bit_rate'].to_i
    end

    def samplerate
      probe[:streams].select {|s| s['codec_type'] == 'audio'}.first['sample_rate'].to_i
    end

    def duration
      probe[:format]['duration'].to_f
    end

    def channels
      probe[:streams].select {|s| s['codec_type'] == 'audio'}.first['channels'].to_i
    end

    def fps
      video = probe[:streams].select {|s| s['codec_type'] == 'video'}.first
      return unless video
      frame_rate = video['r_frame_rate']
      return unless frame_rate
      nu, de = frame_rate.split '/'
      begin
        (nu.to_f/de.to_f).to_i
      rescue FloatDomainError
        nil
      end
    end

    def summary
      puts "
      mimetype: #{mimetype}
      size: #{size}
      bitrate: #{bitrate} bps
      samplerate: #{samplerate} Hz
      duration: #{duration} seconds
      channels #{channels} channels
      fps: #{fps} fps
      "
    end

    def probe
      return @data if @data

      output = %x{ffprobe -show_format -show_streams #@file 2> /dev/null}
      raise "Error running ffprobe, returned #{$?} output: #{output}" unless $?.success?

      @data = Hash.new
      type = nil
      output.lines.each do |line|
        line.chomp!
        if line =~ /^\[\//
          type = nil
        elsif line =~ /^\[STREAM\]/
          type = :stream
          @data[:streams] ||= []
          @data[:streams].push Hash.new
        elsif line =~ /^\[FORMAT\]/
          type = :format
          @data[:format] = Hash.new
        else
          key, value = line.split(/=/)
          if type == :format
            @data[:format][key.strip] = value.strip
          elsif type == :stream
            @data[:streams].last[key.strip] = value.strip
          else
            raise "Unexpected line #{line}"
          end
        end
      end
      @data
    end
  end
end
