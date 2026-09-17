# ## Schema Information
#
# Table name: `languages`
# Database name: `primary`
#
# ### Columns
#
# Name               | Type               | Attributes
# ------------------ | ------------------ | ---------------------------
# **`id`**           | `integer`          | `not null, primary key`
# **`code`**         | `string(255)`      |
# **`dialect`**      | `boolean`          | `default(FALSE), not null`
# **`east_limit`**   | `float(24)`        |
# **`name`**         | `string(255)`      |
# **`north_limit`**  | `float(24)`        |
# **`retired`**      | `boolean`          | `default(FALSE), not null`
# **`source`**       | `string(255)`      | `not null`
# **`south_limit`**  | `float(24)`        |
# **`west_limit`**   | `float(24)`        |
#
# ### Indexes
#
# * `index_languages_on_code_and_source` (_unique_):
#     * **`code`**
#     * **`source`**
#

class Language < ApplicationRecord
  include HasBoundaries

  # Everything Nabu holds about one Source. A Source is the truth for everything on a Language
  # except its Bounding box, so each one is a single entry in SOURCES rather than another literal
  # in every place that names, links or validates a Code.
  #
  # `code_format` is the shape a Source's Codes take, checked against every code each one publishes
  # so a real code is never refused: all 1,204 AUSTLANG codes, 53 of which carry a suffix (A38.1,
  # N116.A), and all 27,177 Glottolog rows, one of which starts with a numeral.
  #
  # `identifier` is the token a Source is known by outside Nabu: the propertyID of an RO-Crate
  # identifier, and the prefix of an OLAC text entry.
  Source = Data.define(:key, :name, :code_format, :uri_template, :identifier) do
    def uri(code)
      format(uri_template, code)
    end

    def code_shaped?(code)
      code.match?(code_format)
    end

    # A person types a code in whatever case they please.
    def code_shaped_any_case?(code)
      code.match?(/#{code_format.source}/i)
    end
  end

  SOURCES = [
    Source.new(key: 'iso639_3', name: 'ISO 639-3', code_format: /\A[a-z]{3}\z/,
               uri_template: 'https://iso639-3.sil.org/code/%s', identifier: 'iso639-3'),
    Source.new(key: 'glottolog', name: 'Glottolog', code_format: /\A[a-z0-9]{4}[0-9]{4}\z/,
               uri_template: 'https://glottolog.org/resource/languoid/id/%s', identifier: 'glottolog'),
    Source.new(key: 'austlang', name: 'AUSTLANG', code_format: /\A[A-Z][0-9]+(\.([0-9]+|[A-Z]))?\z/,
               uri_template: 'https://collection.aiatsis.gov.au/austlang/language/%s', identifier: 'austlang')
  ].index_by(&:key).freeze

  LABEL_ATTRIBUTES = %w[name code source dialect].freeze

  PICKER_RANK = <<~SQL.squish.freeze
    CASE
      WHEN languages.code = :term THEN 0
      WHEN languages.retired THEN 5
      WHEN languages.dialect THEN 4
      WHEN languages.source = '#{SOURCES.fetch('iso639_3').key}' THEN 1
      WHEN languages.source = '#{SOURCES.fetch('glottolog').key}' THEN 2
      ELSE 3
    END
  SQL

  SPECIAL_CODES = %w[mul und zxx].freeze

  has_paper_trail

  after_update_commit :reindex_tagged_records, if: -> { saved_changes.keys.intersect?(LABEL_ATTRIBUTES) }

  enum :source, SOURCES.transform_values(&:key), validate: true

  validates :name, presence: true
  validates :source, presence: true
  validates :code, presence: true, uniqueness: { scope: :source, case_sensitive: false }
  validate :code_matches_its_source

  scope :alpha, -> { order(:name) }

  scope :picker_search, lambda { |term|
    term = term.to_s
    where('languages.name LIKE :pattern OR languages.code LIKE :pattern', pattern: "%#{sanitize_sql_like(term)}%")
      .order(Arel.sql(sanitize_sql_array([PICKER_RANK, { term: }])), :name)
  }

  scope :special, -> { iso639_3.in_order_of(:code, SPECIAL_CODES) }
  scope :tagged, lambda {
    where(id: CollectionLanguage.select(:language_id))
      .or(where(id: ItemContentLanguage.select(:language_id)))
      .or(where(id: ItemSubjectLanguage.select(:language_id)))
  }
  scope :in_countries, ->(country_ids) { where(id: CountriesLanguage.where(country_id: country_ids).select(:language_id)) }

  # The one rendering of a Language wherever a person reads, picks or filters by one.
  def label
    "#{name} (#{code}) · #{label_source_name}"
  end

  # Everything Nabu holds about the registry that issued this Code.
  def source_definition
    SOURCES[source]
  end

  # The Source itself. The Label marks a Glottolog dialect as such, but that is a rendering of
  # source and dialect together, not a Source of its own.
  def source_name
    source_definition&.name
  end

  def picker_description
    'Retired' if retired?
  end

  # How a Language is offered wherever a picker is built. Choices.js carries whatever else a chip
  # needs as the choice's custom properties.
  def picker_option(equivalents = nil)
    properties = { equivalents: } if equivalents.present?

    { value: id, label:, description: picker_description, custom_properties: properties }.compact
  end

  def source_uri
    source_definition&.uri(code)
  end

  def source_identifier
    source_definition&.identifier
  end

  # OLAC's controlled vocabulary is ISO 639 only and olac:code is typed to it, so a Language from
  # any other Source is named in the element's text instead, carrying its own Source and Code.
  def olac_text
    "#{name} [#{source_identifier}:#{code}]"
  end

  has_many :countries_languages
  has_many :countries, through: :countries_languages, dependent: :destroy
  # validates :countries, length: { :minimum => 1 }

  has_many :item_content_languages
  has_many :items_for_content, through: :item_content_languages, source: :item, dependent: :restrict_with_exception

  has_many :item_subject_languages
  has_many :items_for_subject, through: :item_subject_languages, source: :item, dependent: :restrict_with_exception

  has_many :collection_languages
  has_many :collections, through: :collection_languages, dependent: :restrict_with_exception

  # A pair is stored with the lower id first, so each of these holds only the half of a Language's
  # equivalents that falls on its side. They are here to restrict deletion; read #equivalents.
  has_many :equivalents_as_lower_id, class_name: 'LanguageEquivalent', foreign_key: :language_id,
                                     inverse_of: :language, dependent: :restrict_with_exception
  has_many :equivalents_as_higher_id, class_name: 'LanguageEquivalent', foreign_key: :related_language_id,
                                      inverse_of: :related_language, dependent: :restrict_with_exception

  def equivalents
    LanguageEquivalent.involving(self)
  end

  # Every Language a typed token could mean: the one its code shape names in that Source, or every
  # Language of that name. What more than one of them means is the caller's to decide.
  def self.matching_token(token)
    token = token.to_s.strip
    return none if token.blank?

    source = SOURCES.values.find { |candidate| candidate.code_shaped_any_case?(token) }
    by_name = where(name: token)
    return by_name if source.nil?

    by_name.or(where(code: token, source: source.key))
  end

  # Every Source's name, keyed by the enum value stored on a Language.
  def self.source_names
    SOURCES.transform_values(&:name)
  end

  def self.ransackable_attributes(_ = nil)
    %w[code dialect east_limit id name north_limit retired source south_limit west_limit]
  end

  def self.ransackable_associations(_ = nil)
    %w[collection_languages collections countries countries_languages item_content_languages item_subject_languages items_for_content items_for_subject
versions]
  end

  private

  def label_source_name
    return 'Glottolog dialect' if glottolog? && dialect?

    source_name
  end

  def reindex_tagged_records
    LanguageReindexJob.perform_later(self)
  end

  def code_matches_its_source
    return if code.blank?

    definition = source_definition
    return if definition.nil? || definition.code_shaped?(code)

    errors.add(:code, "is not shaped like a #{definition.name} code")
  end
end
