module LanguageRefresh
  # A Source that publishes one table of Codes, names and points and names no replacement for a
  # Code it drops. A subclass says how to fetch the table, which column holds what, and which
  # attributes beyond the name a row carries.
  class TableStage
    def initialize(fetcher)
      @fetcher = fetcher
    end

    def row_count
      rows.size
    end

    def apply(_run)
      published = rows.index_by { |row| code_of(row) }
      languages = Language.where(source:).index_by(&:code)
      @changes = Hash.new { |changes, key| changes[key] = [] }
      %i[new renamed retired_held reinstated boxes_filled location_warnings].each { |key| @changes[key] }

      published.each do |code, row|
        language = languages[code]
        languages[code] = language.nil? ? create(row) : update(language, row)
      end

      languages.each_value { |language| retire(language, published) }

      { changes: @changes, counts: { country_links_added: add_country_links(published, languages) } }
    end

    private

    def create(row)
      language = Language.create!(code: code_of(row), source:, **attributes_of(row), **Location.limits(point(row)))
      @changes[:new] << entry(row)
      language
    end

    # One write per row, so a rename, a Reinstatement and a first box land together and the Label
    # reindex fires once.
    def update(language, row)
      distance = Location.warning_distance(language, point(row))
      @changes[:location_warnings] << entry(row).merge('distance_km' => distance) if distance

      attributes = attributes_of(row).reject { |name, value| language[name] == value }
      attributes[:retired] = false if language.retired?
      attributes.merge!(Location.limits(point(row))) if language.has_no_boundaries?
      return language if attributes.empty?

      @changes[:renamed] << entry(row).merge('old_name' => language.name) if attributes.key?(:name)
      @changes[:dialect_changed] << entry(row) if attributes.key?(:dialect)
      @changes[:reinstated] << entry(row) if attributes.key?(:retired)
      @changes[:boxes_filled] << entry(row) if attributes.key?(:north_limit)
      language.update!(attributes)
      language
    end

    # A Code the Source no longer publishes is Retired where it stands; nothing is rewritten.
    def retire(language, published)
      return if published.key?(language.code) || language.retired?

      language.update!(retired: true)
      @changes[:retired_held] << retired_entry(language)
    end

    def retired_entry(language)
      { 'code' => language.code, 'name' => language.name }
    end

    def entry(row)
      { 'code' => code_of(row), **attributes_of(row).stringify_keys }
    end
  end
end
