# ## Schema Information
#
# Table name: `essences`
# Database name: `primary`
#
# ### Columns
#
# Name                           | Type               | Attributes
# ------------------------------ | ------------------ | ---------------------------
# **`id`**                       | `integer`          | `not null, primary key`
# **`bitrate`**                  | `bigint`           |
# **`channels`**                 | `integer`          |
# **`derived_files_generated`**  | `boolean`          | `default(FALSE)`
# **`doi`**                      | `string(255)`      |
# **`duration`**                 | `float(24)`        |
# **`extracted_content`**        | `text(4294967295)`  |
# **`extracted_content_type`**   | `string(255)`      |
# **`filename`**                 | `string(255)`      |
# **`fps`**                      | `integer`          |
# **`mimetype`**                 | `string(255)`      |
# **`samplerate`**               | `integer`          |
# **`size`**                     | `bigint`           |
# **`created_at`**               | `datetime`         |
# **`updated_at`**               | `datetime`         |
# **`created_by_id`**            | `bigint`           |
# **`item_id`**                  | `integer`          |
#
# ### Indexes
#
# * `index_essences_on_created_by_id`:
#     * **`created_by_id`**
# * `index_essences_on_item_id`:
#     * **`item_id`**
# * `index_essences_on_item_id_and_filename` (_unique_):
#     * **`item_id`**
#     * **`filename`**
#
# ### Foreign Keys
#
# * `fk_rails_...`:
#     * **`created_by_id => users.id`**
#

class Essence < ApplicationRecord
  include IdentifiableByDoi
  include Entityable
  include SearchSortable

  has_paper_trail ignore: %i[extracted_content extracted_content_type]

  searchkick deep_paging: true,
             merge_mappings: true,
             mappings: {
               properties: {
                 extracted_text: {
                   type: 'text',
                   analyzer: 'searchkick_index',
                   fields: {
                     analyzed: {
                       type: 'text',
                       analyzer: 'searchkick_search2'
                     }
                   }
                 },
                 # One nested segment per location-addressed slice of extracted content (PDF page,
                 # ELAN annotation). Segment text carries the same analyzers as extracted_text so
                 # basic and advanced search behave identically inside segments. The location
                 # fields are the contract consumed by Oni deep linking via searchExtra.segments.
                 segments: {
                   type: 'nested',
                   properties: {
                     type: { type: 'keyword' },
                     text: {
                       type: 'text',
                       analyzer: 'searchkick_index',
                       fields: {
                         analyzed: {
                           type: 'text',
                           analyzer: 'searchkick_search2'
                         }
                       }
                     },
                     page: { type: 'integer' },
                     tier: { type: 'keyword' },
                     start_ms: { type: 'long' },
                     end_ms: { type: 'long' }
                   }
                 }
               }
             }

  scope :search_import, lambda {
    includes(item: [
      :collection, :collector, :operator,
      :content_languages, :countries,
      :admins, :users,
      { collection: %i[admins users] }
    ])
  }

  ANNOTATION_EXTENSIONS = %w[eaf trs ixt textgrid cha srt vtt].freeze
  ANNOTATABLE_EXTENSIONS = %w[mp3 ogg oga wav mp4 webm ogv mov mxf mkv].freeze

  # extracted_content_type records which extractor semantics produced the row (for targeted
  # reprocessing); code interprets the column through the content *shape* it maps to, so a new
  # structured format only needs a mapping entry here, not new plumbing.
  EXTRACTED_CONTENT_SHAPES = {
    'text' => :flat,
    'pdf' => :segments,
    'elan' => :segments
  }.freeze

  # Location fields each segment type must carry - the single source of truth consulted by both
  # the GraphQL boundary (ExtractedSegmentInput) and the model validation, so a new segment type
  # is one entry here plus an enum value.
  SEGMENT_REQUIRED_FIELDS = {
    'page' => %w[page],
    'time-aligned-annotation' => %w[tier start_ms end_ms]
  }.freeze

  belongs_to :item, counter_cache: true
  belongs_to :created_by, class_name: 'User', optional: true
  delegate :collection, to: :item
  delegate :collector_name, to: :item

  has_many :outgoing_annotation_links,
           class_name: 'EssenceAnnotation',
           foreign_key: :annotation_essence_id,
           dependent: :destroy,
           inverse_of: :annotation_essence
  has_many :annotates, through: :outgoing_annotation_links, source: :target_essence

  has_many :incoming_annotation_links,
           class_name: 'EssenceAnnotation',
           foreign_key: :target_essence_id,
           dependent: :destroy,
           inverse_of: :target_essence
  has_many :annotated_by, through: :incoming_annotation_links, source: :annotation_essence

  validates :item, associated: true
  validates :filename,
            presence: true,
            uniqueness: { case_sensitive: false, scope: :item_id }
  validates :mimetype, presence: true
  validates :bitrate, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
  validates :samplerate, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
  validates :size, presence: true, numericality: { only_integer: true, greater_than: 0 }, unless: :allowed_zero_file_size?
  validates :duration, numericality: { greater_than: 0, allow_nil: true }
  validates :channels, numericality: { greater_than: 0, allow_nil: true }
  validates :fps, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validates :extracted_content_type, inclusion: { in: EXTRACTED_CONTENT_SHAPES.keys }, allow_nil: true
  validate :extracted_content_and_type_set_together
  validate :extracted_content_matches_shape

  # ensure that the item catalog gets updated when essences are added/removed

  before_save :round_duration
  after_create :update_catalog_metadata
  before_destroy :update_catalog_metadata

  after_commit :sync_parent_entities
  after_create_commit :auto_link_annotations

  def allowed_zero_file_size?
    filename =~ /\.(annis)$/
  end

  def type
    types = mimetype.split('/', 2)
    if types[1].nil?
      'unknown'
    else
      types[1].upcase
    end
  end

  def full_identifier
    "#{item.collection.identifier}/#{item.identifier}/#{filename}"
  end

  def next_essence
    current_essences = Essence.where(item_id:).order(:filename)
    current_essence_index = current_essences.index { |essence| essence.id == id }

    current_essences[current_essence_index + 1]
  end

  def prev_essence
    current_essences = Essence.where(item_id:).order(:filename)
    current_essence_index = current_essences.index { |essence| essence.id == id }

    current_essence_index.zero? ? nil : current_essences[current_essence_index - 1]
  end

  def citation
    cite = ''
    cite += "#{collector_name} (collector)" if item.collector

    item.item_agents.group_by(&:user).map do |user, ias|
      cite += ', ' unless cite == ''
      cite += "#{user.name} (#{ias.map(&:agent_role).map(&:name).join(', ')})"
    end

    cite += ", #{item.originated_on.year}" if item.originated_on
    cite += '. ' unless cite == ''
    cite += type
    cite += '. '
    cite += " #{filename} at catalog.paradisec.org.au."
    cite += doi ? " https://dx.doi.org/#{doi}" : " #{full_path}"
  end

  def title
    filename
  end

  def is_archived?
    filename.ends_with?('.mxf') || filename.ends_with?('.mkv')
  end

  def extension
    File.extname(filename).delete('.').downcase
  end

  def basename
    File.basename(filename, File.extname(filename)).downcase
  end

  def annotation_extension?
    ANNOTATION_EXTENSIONS.include?(extension)
  end

  def annotatable_extension?
    ANNOTATABLE_EXTENSIONS.include?(extension)
  end

  def unmapped_transcript?
    annotation_extension? && outgoing_annotation_links.empty?
  end

  def extracted_content_shape
    EXTRACTED_CONTENT_SHAPES[extracted_content_type]
  end

  # Flat-text view of the extracted content, consumed by the admin essence page and the search
  # document. Returns content only for flat-shaped rows.
  def extracted_text
    extracted_content if extracted_content_shape == :flat
  end

  # Parsed segments view of the extracted content, consumed by the search document.
  # Returns segments only for segments-shaped rows.
  def extracted_segments
    return unless extracted_content_shape == :segments

    JSON.parse(extracted_content)
  end

  def search_data
    {
      entity_type: 'Essence',
      id:,
      filename:,
      mimetype:,
      full_identifier:,
      identifier: full_identifier,
      # Sort values for cross-index Oni search. Essences have no title, so title sorting falls back
      # to the downcased filename; full_identifier_sort is number-aware (downcased + zero-padded
      # numeric runs) so AA1-2 sorts before AA1-10.
      title_sort: filename&.downcase,
      full_identifier_sort: self.class.natural_sort_key(full_identifier),
      collection_identifier: item.collection.identifier,
      item_identifier: item.identifier,

      # Structured rows index segments *instead of* the flat field (no double indexing); a
      # phrase spanning a segment boundary not matching is an accepted trade-off (see #1155).
      extracted_text:,
      segments: extracted_segments,

      languages: item.content_languages.map(&:name).uniq,
      languages_with_code: item.content_languages.map { |l| "#{l.name} (#{l.code})" }.uniq,
      countries: item.countries.map(&:name).uniq,
      collector_name: item.collector_name,

      encodingFormat: [mimetype],
      rootCollection: "#{item.collection.identifier} - #{item.collection.title}",
      collection_title: item.collection.title,

      private: item.private? || item.collection.private?,
      collector_id: item.collector_id,
      operator_id: item.operator_id,
      # Read-visibility union: item editors + read-grantees + collection editors + read-grantees.
      # Consumed by HasSearch#visibility_clauses (an essence inherits its item's/collection's visibility).
      # Essences have no advanced-search facets, so unlike Collection/Item they carry no separate
      # admin_ids/user_ids fields - the union is the only permission data indexed here.
      access_user_ids: (item.admins.map(&:id) + item.users.map(&:id) + item.collection.admins.map(&:id) + item.collection.users.map(&:id)).uniq,

      originated_on: item.originated_on,
      created_at: created_at&.to_date,
      updated_at: updated_at&.to_date
    }
  end

  def self.search_user_fields
    %i[access_user_ids]
  end

  def self.search_agg_fields
    %i[languages_with_code countries collector_name encodingFormat rootCollection entity_type]
  end

  def self.search_text_fields
    %i[full_identifier filename extracted_text]
  end

  def self.search_filter_fields
    %i[private collector_id operator_id mimetype]
  end

  def self.search_highlight_fields
    %i[extracted_text filename]
  end

  def self.search_includes
    [{ item: [:collection, :collector, :content_languages, :countries, :admins, :users,
              { collection: %i[admins users] }] }, :entity]
  end

  def self.ransackable_attributes(_ = nil)
    %w[bitrate channels created_at derived_files_generated doi duration filename fps id item_id mimetype samplerate size updated_at]
  end

  def self.ransackable_associations(_ = nil)
    %w[item versions]
  end

  private

  def extracted_content_and_type_set_together
    return if extracted_content.nil? == extracted_content_type.nil?

    errors.add(:extracted_content_type, 'must be set if and only if extracted_content is set')
  end

  # nabu serialises the segments JSON itself, so this is an internal safety net for non-GraphQL
  # writes. The dirty guard keeps saves that don't touch the (potentially multi-megabyte) content
  # from re-parsing it.
  def extracted_content_matches_shape
    return unless extracted_content_changed? && extracted_content_shape == :segments

    segments = extracted_segments
    return if segments.is_a?(Array) && segments.present? && segments.all? { |segment| valid_segment?(segment) }

    errors.add(:extracted_content, 'must be a JSON array of valid segments')
  rescue JSON::ParserError
    errors.add(:extracted_content, 'must be valid JSON for segments-shaped content types')
  end

  def valid_segment?(segment)
    return false unless segment.is_a?(Hash)

    required_fields = SEGMENT_REQUIRED_FIELDS[segment['type']]
    return false unless required_fields

    segment['text'].is_a?(String) && segment['text'].present? && required_fields.all? { |field| segment[field].present? }
  end

  def update_catalog_metadata
    item.update_catalog_metadata
  end

  def auto_link_annotations
    EssenceAnnotationMatcher.link_for(self)
  end

  def round_duration
    self.duration = duration.round(3) if duration.present?
  end

  def sync_parent_entities
    return unless saved_change_to_mimetype? || saved_change_to_item_id? || previously_new_record? || destroyed?

    item&.entity&.update!(
      media_types: item.essences.distinct.pluck(:mimetype).compact.sort.join(',').presence,
      essences_count: item.essences.count
    )
    item&.collection&.entity&.update!(
      media_types: item.collection.essences.distinct.pluck(:mimetype).compact.sort.join(',').presence,
      essences_count: item.collection.essences.count
    )
  end

  def entity_sync_attributes
    %i[filename mimetype item_id identifier]
  end

  def entity_attributes
    {
      entity: self,
      identifier: full_identifier,
      member_of: item&.full_identifier,
      title: filename,
      originated_on: item&.originated_on,
      media_types: mimetype,
      private: item&.private? || item&.collection&.private? || false,
      items_count: 0,
      essences_count: 0
    }
  end
end
