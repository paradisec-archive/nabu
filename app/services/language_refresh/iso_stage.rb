module LanguageRefresh
  # Brings ISO 639-3 Languages into line with SIL's code table and its retirement list, and adds the
  # country links Ethnologue lists for them. Links are only ever added.
  class IsoStage
    SIL_CODES_URL = 'https://iso639-3.sil.org/sites/iso639-3/files/downloads/iso-639-3.tab'.freeze
    SIL_RETIREMENTS_URL = 'https://iso639-3.sil.org/sites/iso639-3/files/downloads/iso-639-3_Retirements.tab'.freeze
    ETHNOLOGUE_INDEX_URL = 'https://www.ethnologue.com/codes/LanguageIndex.tab'.freeze

    REASONS = { 'C' => 'code change', 'D' => 'duplicate', 'M' => 'merge', 'S' => 'split', 'N' => 'non-existent' }.freeze

    # Only a retirement naming one replacement can be rewritten without a person; a split or a
    # non-existent code leaves its tags where they are for someone to re-tag.
    ONE_TO_ONE = %w[C D M].freeze

    JOIN_TABLES = [*Language::TAGGINGS, CountriesLanguage].freeze

    def initialize(fetcher)
      @fetcher = fetcher
    end

    def source
      'iso639_3'
    end

    def fetch
      @codes = TabFile.new(@fetcher.get(SIL_CODES_URL), %w[Id Ref_Name])
      @retirements = TabFile.new(@fetcher.get(SIL_RETIREMENTS_URL), %w[Id Ref_Name Ret_Reason Change_To Ret_Remedy])
      @index = TabFile.new(@fetcher.get(ETHNOLOGUE_INDEX_URL), %w[LangID CountryID])
    end

    def version
      {
        'iso-639-3.tab' => @codes.version,
        'iso-639-3_Retirements.tab' => @retirements.version,
        'LanguageIndex.tab' => @index.version
      }
    end

    def row_count
      @codes.rows.size
    end

    def apply(run)
      published = @codes.rows.to_h { |row| [row['Id'], row['Ref_Name']] }
      retirements = @retirements.rows.reject { |row| published.key?(row['Id']) }.index_by { |row| row['Id'] }
      languages = Language.iso639_3.index_by(&:code)

      created = create(published, languages)
      renamed = rename(published.merge(retirements.transform_values { |row| row['Ref_Name'] }), languages)
      reinstated = reinstate(published, languages)
      retired = retire(retirements, published, languages, run)

      {
        changes: { new: created, renamed:, **retired.except(:reindex), reinstated: },
        counts: { country_links_added: add_country_links(languages) },
        held: held(retirements),
        reindex: retired[:reindex]
      }
    end

    private

    def create(published, languages)
      published.filter_map do |code, name|
        next if languages.key?(code)

        languages[code] = Language.create!(code:, name:, source:)
        { 'code' => code, 'name' => name }
      end
    end

    # Covers the retirement names too, so a row the old importer suffixed takes SIL's own name back.
    def rename(names, languages)
      names.filter_map do |code, name|
        language = languages[code]
        next if language.nil? || language.name == name

        was = language.name
        language.update!(name:)
        { 'code' => code, 'name' => name, 'old_name' => was }
      end
    end

    def reinstate(published, languages)
      languages.each_value.filter_map do |language|
        next unless language.retired? && published.key?(language.code)

        language.update!(retired: false)
        { 'code' => language.code, 'name' => language.name }
      end
    end

    # A row the old importer or a person retired by hand is still owed its one-to-one rewrite, so a
    # Code SIL no longer publishes is read whether or not the flag is already set. Nothing is
    # reported twice: an old retirement only reappears in the Run that finally moves a tag.
    def retire(retirements, published, languages, run)
      rewritten = []
      held = []
      reindex = []

      languages.each_value do |language|
        next if published.key?(language.code)

        was_retired = language.retired?
        replacement = replacement_for(retirements[language.code], published, languages)
        language.update!(retired: true) unless was_retired

        if replacement.nil?
          held << { 'code' => language.code, 'name' => language.name } unless was_retired
          next
        end

        moved = rewrite(language, replacement, run)
        next if was_retired && moved.zero?

        rewritten << { 'code' => language.code, 'name' => language.name, 'change_to' => replacement.code, 'moved' => moved }
        reindex << replacement.id if moved.positive?
      end

      { retired_rewritten: rewritten, retired_held: held, reindex: }
    end

    def replacement_for(retirement, published, languages)
      return if retirement.nil? || !ONE_TO_ONE.include?(retirement['Ret_Reason'])
      return unless published.key?(retirement['Change_To'])

      languages[retirement['Change_To']]
    end

    # Join-table rewrites keep their versions, so a re-tag can be traced back to the Run that made it.
    def rewrite(language, replacement, run)
      PaperTrail.request(enabled: true, whodunnit: run.whodunnit) do
        JOIN_TABLES.sum { |model| move(model, language, replacement) }
      end
    end

    def move(model, language, replacement)
      parent_key = (model.column_names - %w[id language_id created_at updated_at]).first
      already_tagged = model.where(language_id: replacement.id).pluck(parent_key).to_set
      moved = 0

      model.where(language_id: language.id).find_each do |record|
        already_tagged.include?(record[parent_key]) ? record.destroy! : record.update!(language_id: replacement.id)
        moved += 1
      end

      moved
    end

    # SIL's own words for why each Retired Language still tagged was retired, and what to do about
    # it. The report holds the list itself; this only says what this Source knows about its own.
    def held(retirements)
      Language.iso639_3.where(retired: true).tagged.order(:code).map do |language|
        retirement = retirements[language.code] || {}
        { 'language_id' => language.id, 'reason' => REASONS[retirement['Ret_Reason']], 'remedy' => retirement['Ret_Remedy'].presence }
      end
    end

    def add_country_links(languages)
      countries = Country.pluck(:code, :id).to_h

      CountryLinks.add(@index.rows.filter_map do |row|
        language = languages[row['LangID']]
        country_id = countries[row['CountryID']]
        [language.id, country_id] if language && !language.retired? && country_id
      end)
    end
  end
end
