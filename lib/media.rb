require 'filemagic'
require 'json'
require 'exceptions'

module Nabu
  class Media
    FM = FileMagic.mime
    def initialize(file)
      @file = file
      raise FileNotFound, "Unable to load media information for missing file: #{@file}" unless File.exist? @file
    end

    def mimetype
      return @mimetype if @mimetype
      @mimetype = FM.file @file, true

      #explicitly override the FileMagick-discovered mime information for certain types
      case @mimetype
        when 'application/octet-stream'
          extension = @file.split('.').last
          @mimetype = case extension
            when 'mp3' then 'audio/mpeg'
            when 'jpg' then 'image/jpeg'
            when 'mp4' then 'video/mp4'
            when 'mxf' then 'application/mxf'
            when 'dv'  then 'video/x-dv'
            when 'tab','txt','cha' then 'text/plain'
            else
              Rails.logger.info "unknown mime type for #{@file}"
              @mimetype
          end
        when 'text/x-c', 'text/x-fortran', 'text/x-pascal', 'text/troff'
          @mimetype = 'text/plain'
        when 'video/3gpp'
          @mimetype = 'video/mp4'
        when 'text/html'
          extension = @file.split('.').last
          if extension == 'xml'
            @mimetype = 'text/xml'
          end
        else
          # use the FileMagick response
      end
      @mimetype
    end

    def size
      @size ||= File.size @file
    end

    def bitrate
      return if !is_media?
      probe['format']['bit_rate'].to_i
    end

    def samplerate
      return if !is_media? || !has_audio?
      probe['streams'].select {|s| s['codec_type'] == 'audio'}.first['sample_rate'].to_i
    end

    def duration
      return if !is_media?
      probe['format']['duration'].to_f
    end

    def channels
      return if !is_media? || !has_audio?
      probe['streams'].select {|s| s['codec_type'] == 'audio'}.first['channels'].to_i
    end

    def fps
      return if !is_media?
      video = probe['streams'].select {|s| s['codec_type'] == 'video'}.first
      return unless video
      frame_rate = video['avg_frame_rate']
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
      fps: #{fps} fps"
    end

    private

    def is_media?
      mimetype =~ /^(audio|video)/
    end

    def has_audio?
      probe['streams'].select {|s| s['codec_type'] == 'audio'}.size > 0
    end

    def probe
      return @data if @data

      output = %x{ffprobe -v0 -show_format -show_streams -of json #{@file}}
      raise "Error running ffprobe, returned #{$?} output: #{output}" unless $?.success?

      # deal with invalid UTF-8
      output.encode!('UTF-8', 'UTF-8', :invalid => :replace)

      @data = JSON.parse output

      if @data.empty? or @data['streams'].empty?
        raise "No metadata in output - #{output}"
      end

      @data
    end
  end
end
