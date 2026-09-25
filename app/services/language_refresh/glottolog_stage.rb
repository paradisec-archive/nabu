require 'json'

module LanguageRefresh
  # Brings Glottolog Languages into line with the latest CLDF release: every language and every
  # dialect, never a family and never the Bookkeeping pseudo-family Glottolog parks withdrawn
  # codes under. A release tag is always read from the API, so a Run never reads a moving branch.
  class GlottologStage < TableStage
    RELEASES_URL = 'https://api.github.com/repos/glottolog/glottolog-cldf/releases/latest'.freeze
    LANGUAGES_URL = 'https://raw.githubusercontent.com/glottolog/glottolog-cldf/%s/cldf/languages.csv'.freeze

    # The ISO columns are read by the Equivalents stage rather than here, but a table without them
    # is as broken for a Run as one missing a name, so the whole contract is checked in one place.
    ISO_COLUMN = 'ISO639P3code'.freeze
    # Glottolog's own spelling of the column.
    CLOSEST_ISO_COLUMN = 'Closest_ISO369P3code'.freeze

    COLUMNS = ['ID', 'Name', 'Level', 'Countries', 'Family_ID', 'Latitude', 'Longitude', ISO_COLUMN, CLOSEST_ISO_COLUMN].freeze
    BOOKKEEPING = 'book1242'.freeze
    LEVELS = { 'language' => false, 'dialect' => true }.freeze

    attr_reader :rows

    def source
      'glottolog'
    end

    def fetch
      @tag = latest_tag
      table = CsvFile.new(@fetcher.get(format(LANGUAGES_URL, @tag)), COLUMNS)
      @rows = table.rows.select { |row| LEVELS.key?(row['Level']) && row['Family_ID'] != BOOKKEEPING }
    end

    def version
      { 'languages.csv' => "Glottolog #{@tag.delete_prefix('v')}" }
    end

    # The ISO 639-3 code Glottolog gives each of its Languages, and the closest code where it gives
    # none of its own. Read by the Equivalents stage; nothing here is kept on a Language.
    def iso_codes
      @rows.map { |row| [row['ID'], row[ISO_COLUMN].presence, row[CLOSEST_ISO_COLUMN].presence] }
    end

    private

    def latest_tag
      tag = JSON.parse(@fetcher.get(RELEASES_URL).body)['tag_name']
      raise Fetcher::FetchError, "#{RELEASES_URL} named no release tag" if tag.blank?

      tag
    rescue JSON::ParserError => e
      raise Fetcher::FetchError, "#{RELEASES_URL} did not answer with JSON: #{e.message}"
    end

    def code_of(row)
      row['ID']
    end

    def attributes_of(row)
      { name: row['Name'], dialect: LEVELS[row['Level']] }
    end

    def retired_entry(language)
      super.merge('dialect' => language.dialect?)
    end

    def point(row)
      Location.point(row['Latitude'], row['Longitude'])
    end

    def add_country_links(published, languages)
      countries = Country.pluck(:code, :id).to_h

      CountryLinks.add(published.flat_map do |code, row|
        language = languages[code]
        next [] if language.nil? || language.retired?

        row['Countries'].to_s.split(';').filter_map { |country| [language.id, countries[country]] if countries[country] }
      end)
    end
  end
end
