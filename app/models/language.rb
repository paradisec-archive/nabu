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

  SOURCES = { iso639_3: 'iso639_3', glottolog: 'glottolog', austlang: 'austlang' }.freeze

  SOURCE_NAMES = { 'iso639_3' => 'ISO 639-3', 'glottolog' => 'Glottolog', 'austlang' => 'AUSTLANG' }.freeze

  # Shapes checked against every code each source publishes, so a real code is never refused: all
  # 1,204 AUSTLANG codes, 53 of which carry a suffix (A38.1, N116.A), and all 27,177 Glottolog
  # rows, one of which starts with a numeral.
  CODE_FORMATS = {
    'iso639_3' => /\A[a-z]{3}\z/,
    'glottolog' => /\A[a-z0-9]{4}[0-9]{4}\z/,
    'austlang' => /\A[A-Z][0-9]+(\.([0-9]+|[A-Z]))?\z/
  }.freeze

  SOURCE_URIS = {
    'iso639_3' => 'https://iso639-3.sil.org/code/%s',
    'glottolog' => 'https://glottolog.org/resource/languoid/id/%s',
    'austlang' => 'https://collection.aiatsis.gov.au/austlang/language/%s'
  }.freeze

  has_paper_trail

  enum :source, SOURCES, validate: true

  validates :name, presence: true
  validates :source, presence: true
  validates :code, presence: true, uniqueness: { scope: :source, case_sensitive: false }
  validate :code_matches_its_source

  scope :alpha, -> { order(:name) }

  # The one rendering of a Language wherever a person reads, picks or filters by one.
  def label
    "#{name} (#{code}) · #{source_name}"
  end

  def source_name
    return 'Glottolog dialect' if glottolog? && dialect?

    SOURCE_NAMES[source]
  end

  def source_uri
    template = SOURCE_URIS[source]
    return if template.nil?

    format(template, code)
  end

  def name_with_code
    "#{name} - #{code}"
  end

  def language_archive_link
    "http://www.language-archives.org/language/#{code}"
  end

  has_many :countries_languages
  has_many :countries, through: :countries_languages, dependent: :destroy
  accepts_nested_attributes_for :countries_languages, allow_destroy: true
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

  def self.ransackable_attributes(_ = nil)
    %w[code dialect east_limit id name north_limit retired source south_limit west_limit]
  end

  def self.ransackable_associations(_ = nil)
    %w[collection_languages collections countries countries_languages item_content_languages item_subject_languages items_for_content items_for_subject
versions]
  end

  private

  def code_matches_its_source
    return if code.blank?

    shape = CODE_FORMATS[source]
    return if shape.nil? || code.match?(shape)

    errors.add(:code, "is not shaped like a #{SOURCE_NAMES[source]} code")
  end
end
