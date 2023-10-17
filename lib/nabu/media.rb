require 'filemagic'
require 'json'

module Nabu
  class FileNotFound < StandardError; end

  class Media
    FM = FileMagic.mime
    def initialize(file)
      @file = file
      raise FileNotFound, "Unable to load media information for missing file: #{@file}" unless File.exist? @file
    end

    def size
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

    def probe
      return @data if @data

      output = %x{ffprobe -v 0 -show_format -show_streams -of json #{@file}}
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
