module LanguageRefresh
  # Brings AUSTLANG Languages into line with the dataset AIATSIS publishes on data.gov.au. The CKAN
  # datastore answers the whole table in one call, so a Run never pages and never reads the CSV host
  # the dataset points at. Every AUSTLANG Language is Australian, so every row is linked to Australia.
  class AustlangStage
    DATASTORE_URL = 'https://data.gov.au/data/api/3/action/datastore_search'.freeze
    RESOURCE_ID = 'e9a9ea06-d821-4b53-a05f-877409a1a19c'.freeze
    # Comfortably above the 1,204 rows published, so one call still answers a growing table.
    LIMIT = 5000

    CODE_COLUMN = 'language_code'.freeze
    NAME_COLUMN = 'language_name'.freeze
    LATITUDE_COLUMN = 'approximate_latitude_of_language_variety'.freeze
    LONGITUDE_COLUMN = 'approximate_longitude_of_language_variety'.freeze
    COLUMNS = [CODE_COLUMN, NAME_COLUMN, LATITUDE_COLUMN, LONGITUDE_COLUMN].freeze

    AUSTRALIA = 'AU'.freeze

    def initialize(fetcher)
      @fetcher = fetcher
    end

    def source
      'austlang'
    end

    def fetch
      @table = DatastoreTable.new(@fetcher.get(url), COLUMNS)
    end

    def version
      { 'austlang_dataset' => @table.version }
    end

    def row_count
      @table.rows.size
    end

    def apply(_run)
      published = @table.rows.index_by { |row| row[CODE_COLUMN] }
      languages = Language.austlang.index_by(&:code)
      changes = { new: [], renamed: [], retired_held: [], reinstated: [], boxes_filled: [], location_warnings: [] }

      published.each do |code, row|
        language = languages[code]
        languages[code] = language.nil? ? create(row, changes) : update(language, row, changes)
      end

      languages.each_value { |language| retire(language, published, changes) }

      { changes:, counts: { country_links_added: add_country_links(languages.values_at(*published.keys)) } }
    end

    private

    def url
      "#{DATASTORE_URL}?resource_id=#{RESOURCE_ID}&limit=#{LIMIT}"
    end

    def create(row, changes)
      language = Language.create!(code: row[CODE_COLUMN], name: row[NAME_COLUMN], source:, **Location.limits(point(row)))
      changes[:new] << entry(row)
      language
    end

    # One write per row, so a rename, a Reinstatement and a first box land together and the Label
    # reindex fires once.
    def update(language, row, changes)
      distance = Location.warning_distance(language, point(row))
      changes[:location_warnings] << entry(row).merge('distance_km' => distance) if distance

      attributes = {}
      attributes[:name] = row[NAME_COLUMN] if language.name != row[NAME_COLUMN]
      attributes[:retired] = false if language.retired?
      attributes.merge!(Location.limits(point(row))) if Location.boxless?(language)
      return language if attributes.empty?

      changes[:renamed] << entry(row).merge('old_name' => language.name) if attributes.key?(:name)
      changes[:reinstated] << entry(row) if attributes.key?(:retired)
      changes[:boxes_filled] << entry(row) if attributes.key?(:north_limit)
      language.update!(attributes)
      language
    end

    # AUSTLANG names no replacement for a Code it has dropped, so the Language is Retired where it
    # stands and nothing is rewritten.
    def retire(language, published, changes)
      return if published.key?(language.code) || language.retired?

      language.update!(retired: true)
      changes[:retired_held] << { 'code' => language.code, 'name' => language.name }
    end

    def entry(row)
      { 'code' => row[CODE_COLUMN], 'name' => row[NAME_COLUMN] }
    end

    # AIATSIS writes the rows it has no location for as 0,0, which is in the Atlantic, so that pair
    # is absent rather than a point off the coast of Ghana.
    def point(row)
      point = Location.point(row[LATITUDE_COLUMN], row[LONGITUDE_COLUMN])
      return if point.nil? || (point.latitude.zero? && point.longitude.zero?)

      point
    end

    # Every AUSTLANG Language is Australian, so the link needs nothing from the dataset. Australia
    # missing from the countries table would silently unlink the whole Source, so it fails the stage.
    def add_country_links(languages)
      australia = Country.find_by(code: AUSTRALIA)
      raise "no #{AUSTRALIA} country to link AUSTLANG Languages to" if australia.nil?

      CountryLinks.add(languages.map { |language| [language.id, australia.id] })
    end
  end
end
