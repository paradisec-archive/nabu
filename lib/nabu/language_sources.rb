# frozen_string_literal: true

require 'open-uri'
require 'zip'

module Nabu
  # Fetches and parses the Ethnologue and SIL ISO 639-3 tables used by the import:ethnologue rake tasks
  class LanguageSources
    ETHNOLOGUE_BASE = 'https://www.ethnologue.com/codes'
    ISO639_DOWNLOAD_PAGE = 'https://iso639-3.sil.org/code_tables/download_tables'
    USER_AGENT = 'Mozilla/5.0 (compatible; nabu-import)'

    class FetchError < StandardError; end

    def countries
      tab_rows(fetch("#{ETHNOLOGUE_BASE}/CountryCodes.tab"), 'CountryID')
    end

    def languages
      @languages ||= tab_rows(fetch("#{ETHNOLOGUE_BASE}/LanguageCodes.tab"), 'LangID')
    end

    def language_index
      tab_rows(fetch("#{ETHNOLOGUE_BASE}/LanguageIndex.tab"), 'LangID')
    end

    # code => 'L' (living) or 'X' (extinct)
    def language_status
      @language_status ||= languages.to_h { |code, _country, status, _name| [code, status] }
    end

    def retirements
      tab_rows(iso639_tables[:retirements], 'Ref_Name')
    end

    # code => reference name, for every ISO 639-3 code including extinct and historical ones
    def iso639_names
      @iso639_names ||= tab_rows(iso639_tables[:languages], 'Ref_Name').to_h { |row| [row[0], row[6]] }
    end

    def iso639_zip_url
      @iso639_zip_url ||= ENV['ISO639_ZIP_URL'].presence || discover_iso639_zip_url
    end

    private

    def fetch(url)
      URI.open(url, 'r:utf-8', 'User-Agent' => USER_AGENT).read
    rescue OpenURI::HTTPError, SocketError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout => e
      raise FetchError, "Could not fetch #{url}: #{e.message}"
    end

    def tab_rows(data, header)
      data.each_line.reject { |line| line.include?(header) }.map { |line| line.strip.split("\t") }
    end

    def discover_iso639_zip_url
      page = fetch(ISO639_DOWNLOAD_PAGE)
      url = page[%r{https://iso639-3\.sil\.org/[^"']*iso-639-3_Code_Tables_\d+\.zip}]
      raise FetchError, "Could not find the code tables zip link on #{ISO639_DOWNLOAD_PAGE}, set ISO639_ZIP_URL" unless url

      url
    end

    def iso639_tables
      @iso639_tables ||= begin
        tables = {}
        Zip::File.open_buffer(fetch(iso639_zip_url)) do |zip_file|
          zip_file.each do |entry|
            name = File.basename(entry.name)
            tables[:retirements] = entry.get_input_stream.read if name =~ /^iso-639-3_Retirements.*\.tab$/
            tables[:languages] = entry.get_input_stream.read if name =~ /^iso-639-3(_\d+)?\.tab$/
          end
        end

        %i[retirements languages].each do |table|
          raise FetchError, "#{table} table not found in #{iso639_zip_url}" unless tables[table]
        end

        tables
      end
    end
  end
end
