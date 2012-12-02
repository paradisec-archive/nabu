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
      return @mimetype if @mimetype
      @mimetype = FM.file @file, true
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
      end
      @mimetype
    end

    def size
      @size ||= File.size @file
    end

    def bitrate
      return if !is_media?
      probe[:format]['bit_rate'].to_i
    end

    def samplerate
      return if !is_media? || !has_audio?
      probe[:streams].select {|s| s['codec_type'] == 'audio'}.first['sample_rate'].to_i
    end

    def duration
      return if !is_media?
      probe[:format]['duration'].to_f
    end

    def channels
      return if !is_media? || !has_audio?
      probe[:streams].select {|s| s['codec_type'] == 'audio'}.first['channels'].to_i
    end

    def fps
      return if !is_media?
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
      fps: #{fps} fps"
    end

    private

    def is_media?
      mimetype =~ /^(audio|video)/
    end

    def has_audio?
      probe[:streams].select {|s| s['codec_type'] == 'audio'}.size > 0
    end

    def probe
      return @data if @data

      output = %x{ffprobe -show_format -show_streams #@file 2>&1}
      raise "Error running ffprobe, returned #{$?} output: #{output}" unless $?.success?

      # deal with invlaid UTF-8
      output.encode!('UTF-8', 'UTF-8', :invalid => :replace)

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
          next if key.blank? || value.blank?
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
