module LanguageRefresh
  # Brings ISO 639-3 Languages into line with SIL's code table, and adds the country links
  # Ethnologue lists for them. Links are only ever added.
  class IsoStage
    SIL_CODES_URL = 'https://iso639-3.sil.org/sites/iso639-3/files/downloads/iso-639-3.tab'.freeze
    ETHNOLOGUE_INDEX_URL = 'https://www.ethnologue.com/codes/LanguageIndex.tab'.freeze

    def initialize(fetcher)
      @fetcher = fetcher
    end

    def source
      'iso639_3'
    end

    def fetch
      @codes = TabFile.new(@fetcher.get(SIL_CODES_URL), %w[Id Ref_Name])
      @index = TabFile.new(@fetcher.get(ETHNOLOGUE_INDEX_URL), %w[LangID CountryID])
    end

    def version
      { 'iso-639-3.tab' => @codes.version, 'LanguageIndex.tab' => @index.version }
    end

    def rows
      @codes.rows.size
    end

    def apply
      names = @codes.rows.to_h { |row| [row['Id'], row['Ref_Name']] }
      existing = Language.iso639_3.where(code: names.keys).index_by(&:code)
      created = []
      renamed = []

      names.each do |code, name|
        language = existing[code]
        if language.nil?
          existing[code] = Language.create!(code:, name:, source:)
          created << [code, name]
        elsif language.name != name
          renamed << [code, language.name, name]
          language.update!(name:)
        end
      end

      { changes: { new: created, renamed: }, counts: { country_links_added: add_country_links(existing) } }
    end

    private

    def add_country_links(languages)
      countries = Country.pluck(:code, :id).to_h
      wanted = @index.rows.filter_map do |row|
        language = languages[row['LangID']]
        country_id = countries[row['CountryID']]
        [language.id, country_id] if language && country_id
      end.uniq

      held = CountriesLanguage.where(language_id: wanted.map(&:first).uniq).pluck(:language_id, :country_id).to_set
      added = wanted.reject { |pair| held.include?(pair) }
      CountriesLanguage.insert_all(added.map { |language_id, country_id| { language_id:, country_id: } }) if added.any?
      added.size
    end
  end
end
