module LanguageRefresh
  # Country links are only ever added, never removed, whichever Source supplied them.
  module CountryLinks
    def self.add(pairs)
      pairs = pairs.uniq
      return 0 if pairs.empty?

      linked = CountriesLanguage.where(language_id: pairs.map(&:first).uniq).pluck(:language_id, :country_id).to_set
      added = pairs.reject { |pair| linked.include?(pair) }
      CountriesLanguage.insert_all(added.map { |language_id, country_id| { language_id:, country_id: } }) if added.any?
      added.size
    end
  end
end
