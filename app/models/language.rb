# ## Schema Information
#
# Table name: `languages`
# Database name: `primary`
#
# ### Columns
#
# Name                      | Type               | Attributes
# ------------------------- | ------------------ | ---------------------------
# **`id`**                  | `integer`          | `not null, primary key`
# **`box_origin`**          | `string(255)`      |
# **`code`**                | `string(255)`      |
# **`dialect`**             | `boolean`          | `default(FALSE), not null`
# **`east_limit`**          | `float(24)`        |
# **`latitude`**            | `float(24)`        |
# **`longitude`**           | `float(24)`        |
# **`name`**                | `string(255)`      |
# **`north_limit`**         | `float(24)`        |
# **`previous_latitude`**   | `float(24)`        |
# **`previous_longitude`**  | `float(24)`        |
# **`retired`**             | `boolean`          | `default(FALSE), not null`
# **`source`**              | `string(255)`      | `not null`
# **`south_limit`**         | `float(24)`        |
# **`synonyms`**            | `text(65535)`      |
# **`west_limit`**          | `float(24)`        |
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

  BOX_ORIGINS = { derived: 'derived', hand_set: 'hand_set' }.freeze

  BOX_LIMITS = %i[north_limit south_limit east_limit west_limit].freeze

  has_paper_trail

  enum :source, SOURCES, validate: true
  enum :box_origin, BOX_ORIGINS, validate: { allow_nil: true }

  validates :name, presence: true
  validates :source, presence: true
  validates :code, presence: true, uniqueness: { scope: :source, case_sensitive: false }
  validate :code_matches_its_source

  before_save :record_who_set_the_box
  # A save that never reached #record_who_set_the_box must not leave the statement behind to be
  # read by the next one, which may be a person moving a limit.
  after_validation :forget_stated_box_origin, if: -> { errors.any? }
  after_rollback :forget_stated_box_origin

  scope :alpha, -> { order(:name) }

  # The Refresh states the origin as it writes a box from the source's point. Anyone who moves a
  # limit without stating one — a person in ActiveAdmin — takes the box over instead.
  def box_origin=(value)
    @box_origin_stated = true
    super
  end

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
    %w[box_origin code dialect east_limit id latitude longitude name north_limit retired source south_limit synonyms west_limit]
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

  # A box a person touched is theirs from then on and the Refresh leaves it alone.
  def record_who_set_the_box
    stated = @box_origin_stated
    @box_origin_stated = false
    return if stated
    return unless BOX_LIMITS.any? { |limit| public_send(:"#{limit}_changed?") }

    write_attribute(:box_origin, box_empty? ? nil : BOX_ORIGINS[:hand_set])
  end

  # Deliberately not HasBoundaries#has_all_boundaries?, whose `?` predicates read a limit of
  # exactly 0.0 as absent: that would drop the marker from a Derived box on the equator and let
  # the next Refresh overwrite a box a person had taken over.
  def box_empty?
    BOX_LIMITS.all? { |limit| public_send(limit).nil? }
  end

  def forget_stated_box_origin
    @box_origin_stated = false
  end
end
