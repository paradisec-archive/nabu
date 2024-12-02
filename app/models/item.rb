# ## Schema Information
#
# Table name: `items`
#
# ### Columns
#
# Name                           | Type               | Attributes
# ------------------------------ | ------------------ | ---------------------------
# **`id`**                       | `integer`          | `not null, primary key`
# **`access_narrative`**         | `text(16777215)`   |
# **`admin_comment`**            | `text(16777215)`   |
# **`born_digital`**             | `boolean`          |
# **`description`**              | `text(16777215)`   | `not null`
# **`dialect`**                  | `string(255)`      |
# **`digitised_on`**             | `datetime`         |
# **`doi`**                      | `string(255)`      |
# **`east_limit`**               | `float(24)`        |
# **`essences_count`**           | `integer`          |
# **`external`**                 | `boolean`          | `default(FALSE)`
# **`identifier`**               | `string(255)`      | `not null`
# **`ingest_notes`**             | `text(16777215)`   |
# **`language`**                 | `string(255)`      |
# **`metadata_exportable`**      | `boolean`          |
# **`metadata_exported_on`**     | `datetime`         |
# **`metadata_imported_on`**     | `datetime`         |
# **`north_limit`**              | `float(24)`        |
# **`original_media`**           | `text(16777215)`   |
# **`originated_on`**            | `date`             |
# **`originated_on_narrative`**  | `text(16777215)`   |
# **`private`**                  | `boolean`          |
# **`received_on`**              | `datetime`         |
# **`region`**                   | `string(255)`      |
# **`south_limit`**              | `float(24)`        |
# **`tapes_returned`**           | `boolean`          |
# **`title`**                    | `string(255)`      | `not null`
# **`tracking`**                 | `text(16777215)`   |
# **`url`**                      | `string(255)`      |
# **`west_limit`**               | `float(24)`        |
# **`created_at`**               | `datetime`         | `not null`
# **`updated_at`**               | `datetime`         | `not null`
# **`access_condition_id`**      | `integer`          |
# **`collection_id`**            | `integer`          | `not null`
# **`collector_id`**             | `integer`          | `not null`
# **`discourse_type_id`**        | `integer`          |
# **`operator_id`**              | `integer`          |
# **`university_id`**            | `integer`          |
#
# ### Indexes
#
# * `index_items_on_access_condition_id`:
#     * **`access_condition_id`**
# * `index_items_on_collection_id`:
#     * **`collection_id`**
# * `index_items_on_collector_id`:
#     * **`collector_id`**
# * `index_items_on_discourse_type_id`:
#     * **`discourse_type_id`**
# * `index_items_on_identifier_and_collection_id` (_unique_):
#     * **`identifier`**
#     * **`collection_id`**
# * `index_items_on_operator_id`:
#     * **`operator_id`**
# * `index_items_on_university_id`:
#     * **`university_id`**
#
class Item < ApplicationRecord
  include IdentifiableByDoi
  include HasBoundaries
  include ActionView::Helpers::SanitizeHelper

  delegate :url_helpers, to: 'Rails.application.routes'
  has_paper_trail
  nilify_blanks

  belongs_to :collection
  belongs_to :collector, class_name: 'User'
  belongs_to :operator, class_name: 'User', optional: true
  belongs_to :university, optional: true
  belongs_to :access_condition, optional: true
  belongs_to :discourse_type, optional: true

  has_many :item_countries, dependent: :destroy
  has_many :countries, through: :item_countries, validate: true

  has_many :item_subject_languages, dependent: :destroy
  has_many :subject_languages, through: :item_subject_languages, source: :language, validate: true

  has_many :item_content_languages, dependent: :destroy
  has_many :content_languages, through: :item_content_languages, source: :language, validate: true

  has_many :item_admins, dependent: :destroy
  has_many :admins, through: :item_admins, validate: true, source: :user

  has_many :item_users, dependent: :destroy
  has_many :users, through: :item_users, validate: true, source: :user

  has_many :item_agents, dependent: :destroy
  has_many :agents, through: :item_agents, validate: true, source: :user

  has_many :item_data_categories, dependent: :destroy
  has_many :data_categories, through: :item_data_categories, validate: true

  has_many :item_data_types, dependent: :destroy
  has_many :data_types, through: :item_data_types, validate: true

  has_many :essences, dependent: :restrict_with_exception
  has_many :comments, as: :commentable, dependent: :destroy

  # require presence of these three fields.
  validates :identifier,
            presence: true,
            uniqueness: { case_sensitive: false, scope: %i[collection_id identifier] },
            format: { with: /\A[a-zA-Z0-9_]*\z/, message: "error - only letters and numbers and '_' allowed" },
            length: { in: 2..30 }
  validates :title, presence: true

  validates :north_limit, numericality: { greater_than_or_equal_to: -90, less_then_or_equal_to: 90 }, allow_nil: true
  validates :south_limit, numericality: { greater_than_or_equal_to: -90, less_then_or_equal_to: 90 }, allow_nil: true
  validates :west_limit, numericality: { greater_than_or_equal_to: -180, less_then_or_equal_to: 180 }, allow_nil: true
  validates :east_limit, numericality: { greater_than_or_equal_to: -180, less_then_or_equal_to: 180 }, allow_nil: true

  bulk = %i[
    bulk_edit_append_title bulk_edit_append_description bulk_edit_append_region
    bulk_edit_append_originated_on_narrative bulk_edit_append_url bulk_edit_append_language
    bulk_edit_append_dialect bulk_edit_append_original_media bulk_edit_append_ingest_notes
    bulk_edit_append_tracking bulk_edit_append_access_narrative bulk_edit_append_admin_comment
    bulk_edit_append_country_ids bulk_edit_append_subject_language_ids bulk_edit_append_content_language_ids
    bulk_edit_append_admin_ids bulk_edit_append_user_ids bulk_edit_append_data_category_ids bulk_edit_append_data_type_ids

    bulk_delete_country_ids bulk_delete_subject_language_ids
    bulk_delete_content_language_ids bulk_delete_data_category_ids bulk_delete_data_type_ids
  ]
  attr_reader(*bulk)

  accepts_nested_attributes_for :item_agents, allow_destroy: true, reject_if: :all_blank

  delegate :name, to: :collector, prefix: true, allow_nil: true
  delegate :sortname, to: :collector, prefix: true, allow_nil: true
  delegate :name, to: :operator, prefix: true, allow_nil: true
  delegate :name, to: :university, prefix: true, allow_nil: true
  delegate :name, to: :discourse_type, prefix: true, allow_nil: true
  delegate :name, to: :access_condition, prefix: true, allow_nil: true

  paginates_per 10

  after_initialize :prefill

  before_save :propagate_collector
  after_save :update_collection_countries_and_languages
  after_save :update_catalog_metadata

  scope :public_items, -> { joins(:collection).where(private: false, collection: { private: false }) }

  def default_map_boundaries?
    return false unless north_limit && south_limit && east_limit && west_limit

    (north_limit - 80.0).abs < Float::EPSILON &&
      (south_limit - -80.0).abs < Float::EPSILON &&
      (east_limit - -40.0).abs < Float::EPSILON &&
      (west_limit - -20.0).abs < Float::EPSILON
  end

  def propagate_collector
    return unless collector_id_changed?

    unless collector_id_was.nil?
      collector_was = User.find(collector_id_was)
      # we're removing one item from the users's 'owned' items
      collector_was.collector = (collector_was.owned_items.count + collector_was.owned_collections.count - 1).positive?
      collector_was.save
    end
    collector.collector = true
    collector.save
  end

  def public?
    !private && !collection.private
  end

  def full_identifier
    "#{collection.identifier}-#{identifier}"
  end

  def full_path
    # FIX ME
    "http://catalog.paradisec.org.au/collections/#{collection.identifier}/items/#{identifier}"
  end

  def xml_key
    "paradisec.org.au/item/#{full_identifier}"
  end

  def essence_types
    essences.map(&:type).uniq
  end

  def prefill
    return unless new_record?
    return unless collection

    self.university_id ||= collection.university_id
    self.collector_id ||= collection.collector_id
    self.operator_id ||= collection.operator_id

    self.region ||= collection.region
    self.north_limit ||= collection.north_limit
    self.south_limit ||= collection.south_limit
    self.west_limit ||= collection.west_limit
    self.east_limit ||= collection.east_limit
    self.country_ids ||= collection.country_ids
    self.subject_language_ids ||= collection.language_ids
    self.content_language_ids ||= collection.language_ids

    self.access_condition_id ||= collection.access_condition_id
    self.access_narrative ||= collection.access_narrative
    self.private ||= collection.private
    self.admin_ids ||= collection.admin_ids
  end

  def inherit_details_from_collection(override = false)
    return unless collection

    inherited_attributes = {
      subject_languages: collection.languages,
      content_languages: collection.languages,
      access_condition: collection.access_condition,
      operator: collection.operator,
      countries: collection.countries,
      north_limit: collection.north_limit,
      south_limit: collection.south_limit,
      east_limit: collection.east_limit,
      west_limit: collection.west_limit,
      access_narrative: collection.access_narrative,
      region: collection.region
    }

    unless override
      # by default, only inherit attributes which don't already have a value
      existing_attributes = Hash[*inherited_attributes.keys.map do |key|
                                    val = public_send(key)
                                    [key.to_sym, val] if val.present?
                                  end.reject { |x| x.nil? }.flatten(1)]
      # -> this merge causes the current attribute value to replace the inherited one before we update
      inherited_attributes = inherited_attributes.merge(existing_attributes)
    end
    # since the attributes here are already explicitly whitelisted, just inherit them and don't add to attr_accessible

    inherited_attributes.each_pair do |key, val|
      public_send("#{key}=", val)
    end
    save
  end

  def self.sortable_columns
    %w[full_identifier title collector_sortname updated_at language countries essences_count]
  end

  searchkick geo_shape: [:bounds], word_start: %i[identifier full_identifier collection_identifier], deep_paging: true

  def self.search_includes
    includes = %i[
      collection collector countries collector operator essences university content_languages
      data_categories data_types discourse_type access_condition subject_languages
    ]
    includes << { item_agents: %i[user agent_role] }

    includes
  end

  def self.search_user_fields
    %i[admin_ids user_ids]
  end

  def self.search_agg_fields
    %i[content_languages countries collector_name]
  end

  def self.search_text_fields
    %i[
      full_identifier
      title description
      originated_on originated_on_narrative url language dialect region received_on digitised_on metadata_imported_on metadata_exported_on ingest_notes tracking
      filename original_media access_narrative admin_comment
    ]
  end

  def self.search_filter_fields
    %i[
      private external no_files
      title_blank description_blank
      originated_on_blank originated_on_narrative_blank url_blank language_blank dialect_blank region_blank original_media_blank admin_comment_blank
      received_on_blank digitised_on_blank metadata_imported_on_blank metadata_exported_on_blank ingest_notes_blank tracking_blank access_narrative_blank
      collector_id country_ids subject_language_ids content_language_ids operator_id university_id data_category_ids data_type_ids discourse_type_id agent_id
      admin_ids user_ids access_condition_id
      mimetype framesPerSecond samplerate channels
      metadata_exportable born_digital tapes_returned
      created_at_blank updated_at_blank
      created_at updated_at
    ]
  end

  scope :search_import,
        lambda {
          # includes(:university, :collector, :operator, :field_of_research, :languages, :countries, :admins, :grants, items: %i[admins users])
          includes(:users, :content_languages, :subject_languages, :countries, :university, :data_types, :data_categories, :discourse_type,
                   :essences, :collection, :collector, :operator,
                   :item_admins, :item_agents, :item_users)
        }

  def search_data
    data = {
      # Full text plus advanced search
      id:,
      identifier:,
      collection_identifier: collection.identifier,
      full_identifier:,
      title:,
      description:,
      region:,
      dialect:,
      language:,
      discourse_type_name:,
      access_narrative:,
      ingest_notes:,
      tracking:,
      original_media:,

      # Extra things for basic full text search
      collector_name:,
      collector_sortname:,
      university_name:,
      operator_name:,
      content_languages: content_languages.map(&:name),
      content_languages_code: content_languages.map(&:code),
      subject_languages: subject_languages.map(&:name),
      countries: countries.map(&:name),
      country_codes: countries.map(&:code),
      data_categories: data_categories.map(&:name),
      data_types: data_types.map(&:name),
      filename: essences.map(&:filename),
      mimetype: essences.map(&:mimetype),

      external:,
      private:,

      # Link models for dropdowns and aggs
      content_language_ids: content_languages.map(&:id),
      data_category_ids: data_categories.map(&:id),
      data_type_ids: data_types.map(&:id),
      subject_language_ids: subject_languages.map(&:id),
      collection_id:,
      collector_id:,
      operator_id:,
      country_ids: countries.map(&:id),
      university_id:,
      access_condition_id:,
      discourse_type_id:,
      admin_ids: item_admins.map(&:user_id),
      agent_ids: item_agents.map(&:user_id),
      user_ids: item_users.map(&:user_id),
      originated_on:,
      metadata_exportable:,
      born_digital:,
      tapes_returned:,

      received_on: received_on&.to_date,
      digitised_on: digitised_on&.to_date,
      metadata_imported_on: metadata_imported_on&.to_date,
      metadata_exported_on: metadata_exported_on&.to_date,

      created_at: created_at.to_date,
      updated_at: updated_at.to_date
    }

    if north_limit
      # TODO: Should this be allowed in the data?
      data[:bounds] = if north_limit == south_limit && east_limit == west_limit
                        { type: 'point', coordinates: [west_limit, north_limit] }
      else
                        {
                          type: 'polygon',
                          coordinates: [[
                            [west_limit, north_limit],
                            [east_limit, north_limit],
                            [east_limit, south_limit],
                            [west_limit, south_limit],
                            [west_limit, north_limit]
                          ]]
                        }
      end
    end

    # Things we want to check blankness of
    blank_fields = %i[
      title description originated_on originated_on_narrative url language dialect region original_media received_on
      digitised_on ingest_notes metadata_imported_on metadata_exported_on tracking access_narrative admin_comment
    ]
    blank_fields.each do |field|
      data["#{field}_blank"] = public_send(field).blank?
    end

    data
  end

  def next_item
    Item.where(collection_id: collection).order(:identifier).where('identifier > ?', identifier).first
  end

  def prev_item
    Item.where(collection_id: collection).order(:identifier).where('identifier < ?', identifier).last
  end

  def citation
    cite = ''
    cite += "#{collector.name} (collector)" if collector
    item_agents.group_by(&:user).map do |user, ias|
      cite += ', ' unless cite == ''
      cite += "#{user.name} (#{ias.map(&:agent_role).map(&:name).join(', ')})"
    end
    cite += ", #{originated_on.year}" if originated_on
    cite += '. ' unless cite == ''
    cite += "<i>#{sanitize(title)}</i>. "
    last = essence_types.count - 1
    essence_types.each_with_index do |type, index|
      cite += type
      cite += if index == last
                '. '
      else
                '/'
      end
    end
    cite += " #{collection.identifier}-#{identifier} at catalog.paradisec.org.au."
    cite += if doi
              " https://dx.doi.org/#{doi}"
    else
              " #{full_path}"
    end
    cite
  end

  def coordinates?
    (north_limit && north_limit != 0) ||
      (south_limit && south_limit != 0) ||
      (west_limit && west_limit != 0) ||
      (east_limit && east_limit != 0)
  end

  def csv_countries
    countries.map(&:name).join(';')
  end

  def csv_content_languages
    content_languages.map(&:name).join(';')
  end

  def csv_subject_languages
    subject_languages.map(&:name).join(';')
  end

  def csv_data_categories
    data_categories.map(&:name).join(';')
  end

  def csv_data_types
    data_types.map(&:name).join(';')
  end

  def csv_item_agents
    result = ''
    item_agents.each do |agent|
      result += "#{agent.user.name} (#{agent.agent_role.name});"
    end
    result
  end

  def csv_filenames
    essences.map(&:filename).join(';')
  end

  def csv_mimetypes
    essences.map(&:mimetype).join(';')
  end

  def csv_fps_values
    essences.map(&:fps).join(';')
  end

  def csv_samplerates
    essences.map(&:samplerate).join(';')
  end

  def csv_channel_counts
    essences.map(&:channels).join(';')
  end

  # OAI-MPH mappings for OLAC
  # If we need to later on we can generate the XML directly
  # TODO
  # - The <request> header doesn't have the params to the request as XML attributes
  def to_olac
    xml = ::Builder::XmlMarkup.new
    xml.tag! 'olac:olac', OAI::Provider::Metadata::Olac.instance.header_specification do
      xml.tag! 'dc:title', title

      xml.tag! 'dc:identifier', full_identifier
      unless external?
        xml.tag! 'dc:identifier', "http://catalog.paradisec.org.au/repository/#{collection.identifier}/#{identifier}",
                 'xsi:type' => 'dcterms:URI'
      end
      xml.tag! 'dc:identifier', url if url?

      xml.tag! 'dc:subject', 'xsi:type' => 'olac:linguistic-field', 'olac:code' => 'language_documentation'

      if originated_on
        xml.tag! 'dcterms:created', originated_on, 'xsi:type' => 'dcterms:W3CDTF'
        xml.tag! 'dc:date', originated_on, 'xsi:type' => 'dcterms:W3CDTF'
      end

      essences.each do |essence|
        unless /PDSC_ADMIN/.match(essence.filename)
          xml.tag! 'dcterms:tableOfContents', "http://catalog.paradisec.org.au/repository/#{collection.identifier}/#{identifier}/#{essence.filename}",
                   'xsi:type' => 'dcterms:URI'
        end
      end

      xml.tag! 'dc:contributor', collector_name, 'xsi:type' => 'olac:role', 'olac:code' => 'compiler' if collector

      item_agents.each do |agent|
        xml.tag! 'dc:contributor', agent.user.name, 'xsi:type' => 'olac:role', 'olac:code' => agent.agent_role.name
      end

      subject_languages.each do |language|
        xml.tag! 'dc:subject', 'xsi:type' => 'olac:language', 'olac:code' => language.code
      end
      content_languages.each do |language|
        xml.tag! 'dc:language', 'xsi:type' => 'olac:language', 'olac:code' => language.code
      end

      format = ''
      format += "Digitised: #{digitised_on? ? 'yes' : 'no'}"
      format += "\nMedia: #{original_media}" if original_media.present?
      format += "\nAudio Notes: #{ingest_notes}" if ingest_notes.present?
      xml.tag! 'dc:format', format
      countries.each do |country|
        xml.tag! 'dc:coverage', country.code, 'xsi:type' => 'dcterms:ISO3166'
      end

      if coordinates?
        location = ''
        location += "northlimit=#{north_limit}; southlimit=#{south_limit}; "
        location += "westlimit=#{west_limit}; eastlimit=#{east_limit}"
        xml.tag! 'dc:coverage', location, 'xsi:type' => 'dcterms:Box'
      end

      data_categories.each do |data_category|
        case data_category.name
        when 'historical reconstruction', 'historical_text'
          xml.tag! 'dc:subject', 'xsi:type' => 'olac:linguistic-field', 'olac:code' => 'historical_linguistics'
        when 'language description'
          xml.tag! 'dc:type', 'xsi:type' => 'olac:linguistic-type', 'olac:code' => 'language_description'
          xml.tag! 'dc:subject', 'xsi:type' => 'olac:linguistic-field', 'olac:code' => 'language_documentation'
        when 'lexicon'
          xml.tag! 'dc:type', 'xsi:type' => 'olac:linguistic-type', 'olac:code' => 'lexicon'
          xml.tag! 'dc:subject', 'xsi:type' => 'olac:linguistic-field', 'olac:code' => 'lexicography'
        when 'primary text'
          xml.tag! 'dc:type', 'xsi:type' => 'olac:linguistic-type', 'olac:code' => 'primary_text'
          xml.tag! 'dc:subject', 'xsi:type' => 'olac:linguistic-field', 'olac:code' => 'text_and_corpus_linguistics'
        when 'song'
          xml.tag! 'dc:subject', ' xsi:type' => 'olac:discourse-type', 'olac:code' => 'singing'
        when 'typological analysis'
          xml.tag! 'dc:subject', data_category.name, 'xsi:type' => 'olac:linguistic-field', 'olac:code' => 'typology'
        when 'instrumental music'
          xml.tag! 'dc:type', 'instrumental music'
        else
          # ignore
        end
      end

      data_types.each do |data_type|
        xml.tag! 'dc:type', data_type.name, 'xsi:type' => 'dcterms:DCMIType'
      end

      if access_condition
        access = access_condition.name
        access += ", #{access_narrative}" if access_narrative.present?
        xml.tag! 'dcterms:accessRights', access
        xml.tag! 'dc:rights', access_condition.name
      end

      xml.tag! 'dcterms:bibliographicCitation', strip_tags(citation)
      xml.tag! 'dc:description', (description + ". Language as given: #{language}")
    end

    xml.target!
  end

  def to_param
    identifier
  end

  # ensure the collection mentions all countries and languages present in the item
  def update_collection_countries_and_languages
    collection_updated = false

    new_item_countries = countries - collection.countries
    if new_item_countries.any?
      collection.countries.concat new_item_countries
      collection_updated = true
    end

    new_languages = Set.new
    new_languages += content_languages
    new_languages += subject_languages
    new_languages -= collection.languages
    if new_languages.any?
      collection.languages.concat new_languages.to_a
      collection_updated = true
    end

    return unless collection_updated

    collection.save
  end

  def access_class
    AccessCondition.access_classification(access_condition)
  end

  def bulk_deleteable
    @bulk_deleteable ||= {}
  end

  def update_catalog_metadata
    CatalogMetadataJob.perform_later(self, true)
  end

  def center_coordinate
    return [] unless coordinates?

    lng = if east_limit < west_limit
            180 + ((west_limit + east_limit) / 2)
    else
            (west_limit + east_limit) / 2
    end

    lat = (north_limit + south_limit) / 2

    [lng, lat]
  end

  def as_geo_json(url)
    date = originated_on.to_time if originated_on
    date ||= created_at

    json = {
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: center_coordinate
      },
      properties: {
        id: full_identifier,
        name: title,
        url:,
        public: true,
        publisher: collector.name,
        contact: 'admin@paradisec.org.au',
        udatestart: date.to_i * 1000
      }
    }

    json[:properties][:description] = description if description
    json[:properties][:languages] = subject_languages.map(&:name_with_code).join(', ') unless subject_languages.empty?
    json[:properties][:countries] = countries.map(&:name_with_code).join(', ') unless countries.empty?
    json[:properties][:license] = access_condition.name if access_condition
    json[:properties][:rights] = access_condition.name if access_condition

    json
  end

  def self.ransackable_attributes(_ = nil)
    %w[
      access_condition_id access_narrative admin_comment born_digital collection_id
      collector_id created_at description dialect digitised_on discourse_type_id doi
      east_limit essences_count external id identifier ingest_notes language
      metadata_exportable metadata_exported_on metadata_imported_on north_limit
      operator_id original_media originated_on originated_on_narrative private received_on
      region south_limit tapes_returned title tracking university_id updated_at url west_limit
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[
      access_condition admins agents collection collector comments content_languages countries
      data_categories data_types discourse_type essences item_admins item_agents
      item_content_languages item_countries item_data_categories item_data_types
      item_subject_languages item_users operator subject_languages university users versions
    ]
  end
end
