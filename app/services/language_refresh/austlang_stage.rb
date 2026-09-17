module LanguageRefresh
  # Brings AUSTLANG Languages into line with the dataset AIATSIS publishes on data.gov.au. The CKAN
  # datastore answers the whole table in one call, so a Run never pages and never reads the CSV host
  # the dataset points at. Every AUSTLANG Language is Australian, so every row is linked to Australia.
  class AustlangStage < TableStage
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

    def source
      'austlang'
    end

    def fetch
      @table = DatastoreTable.new(@fetcher.get(url), COLUMNS)
    end

    def version
      { 'austlang_dataset' => @table.version }
    end

    def rows
      @table.rows
    end

    private

    def url
      "#{DATASTORE_URL}?resource_id=#{RESOURCE_ID}&limit=#{LIMIT}"
    end

    def code_of(row)
      row[CODE_COLUMN]
    end

    def attributes_of(row)
      { name: row[NAME_COLUMN] }
    end

    # AIATSIS writes the rows it has no location for as 0,0, which is in the Atlantic, so that pair
    # is absent rather than a point off the coast of Ghana.
    def point(row)
      point = Location.point(row[LATITUDE_COLUMN], row[LONGITUDE_COLUMN])
      return if point.nil? || (point.latitude.zero? && point.longitude.zero?)

      point
    end

    # Australia missing from the countries table would silently unlink the whole Source, so it
    # fails the stage.
    def add_country_links(published, languages)
      australia = Country.find_by(code: AUSTRALIA)
      raise "no #{AUSTRALIA} country to link AUSTLANG Languages to" if australia.nil?

      CountryLinks.add(languages.values_at(*published.keys).map { |language| [language.id, australia.id] })
    end
  end
end
