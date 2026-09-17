require 'json'

module LanguageRefresh
  # Brings Glottolog Languages into line with the latest CLDF release: every language and every
  # dialect, never a family and never the Bookkeeping pseudo-family Glottolog parks withdrawn
  # codes under. A release tag is always read from the API, so a Run never reads a moving branch.
  class GlottologStage
    RELEASES_URL = 'https://api.github.com/repos/glottolog/glottolog-cldf/releases/latest'.freeze
    LANGUAGES_URL = 'https://raw.githubusercontent.com/glottolog/glottolog-cldf/%s/cldf/languages.csv'.freeze

    COLUMNS = %w[ID Name Level Countries Family_ID Latitude Longitude].freeze
    BOOKKEEPING = 'book1242'.freeze
    LEVELS = { 'language' => false, 'dialect' => true }.freeze

    def initialize(fetcher)
      @fetcher = fetcher
    end

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

    def row_count
      @rows.size
    end

    def apply(_run)
      published = @rows.index_by { |row| row['ID'] }
      languages = Language.glottolog.index_by(&:code)
      changes = { new: [], renamed: [], dialect_changed: [], retired_held: [], reinstated: [], boxes_filled: [], location_warnings: [] }

      published.each do |code, row|
        language = languages[code]
        languages[code] = language.nil? ? create(row, changes) : update(language, row, changes)
      end

      languages.each_value { |language| retire(language, published, changes) }

      { changes:, counts: { country_links_added: add_country_links(published, languages) }, held: }
    end

    private

    def latest_tag
      tag = JSON.parse(@fetcher.get(RELEASES_URL).body)['tag_name']
      raise Fetcher::FetchError, "#{RELEASES_URL} named no release tag" if tag.blank?

      tag
    rescue JSON::ParserError => e
      raise Fetcher::FetchError, "#{RELEASES_URL} did not answer with JSON: #{e.message}"
    end

    def create(row, changes)
      language = Language.create!(code: row['ID'], name: row['Name'], source:, dialect: LEVELS[row['Level']], **Location.limits(point(row)))
      changes[:new] << entry(row)
      language
    end

    # One write per row, so a rename, a dialect reclassification, a Reinstatement and a first box
    # all land together and the Label reindex fires once.
    def update(language, row, changes)
      distance = Location.warning_distance(language, point(row))
      changes[:location_warnings] << entry(row).merge('distance_km' => distance) if distance

      attributes = {}
      attributes[:name] = row['Name'] if language.name != row['Name']
      attributes[:dialect] = LEVELS[row['Level']] if language.dialect? != LEVELS[row['Level']]
      attributes[:retired] = false if language.retired?
      attributes.merge!(Location.limits(point(row))) if Location.boxless?(language)
      return language if attributes.empty?

      changes[:renamed] << entry(row).merge('old_name' => language.name) if attributes.key?(:name)
      changes[:dialect_changed] << entry(row) if attributes.key?(:dialect)
      changes[:reinstated] << entry(row) if attributes.key?(:retired)
      changes[:boxes_filled] << entry(row) if attributes.key?(:north_limit)
      language.update!(attributes)
      language
    end

    # A glottocode Glottolog no longer publishes, or has moved under Bookkeeping, is Retired where
    # it stands; nothing is rewritten, because Glottolog names no replacement.
    def retire(language, published, changes)
      return if published.key?(language.code) || language.retired?

      language.update!(retired: true)
      changes[:retired_held] << { 'code' => language.code, 'name' => language.name, 'dialect' => language.dialect? }
    end

    def point(row)
      Location.point(row['Latitude'], row['Longitude'])
    end

    def entry(row)
      { 'code' => row['ID'], 'name' => row['Name'], 'dialect' => LEVELS[row['Level']] }
    end

    def add_country_links(published, languages)
      countries = Country.pluck(:code, :id).to_h

      CountryLinks.add(published.flat_map do |code, row|
        language = languages[code]
        next [] if language.nil? || language.retired?

        row['Countries'].to_s.split(';').filter_map { |country| [language.id, countries[country]] if countries[country] }
      end)
    end

    def held
      Language.glottolog.where(retired: true).tagged.order(:code).map { |language| { 'language_id' => language.id } }
    end
  end
end
