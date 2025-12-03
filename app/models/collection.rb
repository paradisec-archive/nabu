# ## Schema Information
#
# Table name: `collections`
#
# ### Columns
#
# Name                         | Type               | Attributes
# ---------------------------- | ------------------ | ---------------------------
# **`id`**                     | `integer`          | `not null, primary key`
# **`access_narrative`**       | `text(16777215)`   |
# **`comments`**               | `text(16777215)`   |
# **`complete`**               | `boolean`          |
# **`deposit_form_received`**  | `boolean`          |
# **`description`**            | `text(16777215)`   | `not null`
# **`doi`**                    | `string(255)`      |
# **`east_limit`**             | `float(24)`        |
# **`has_deposit_form`**       | `boolean`          |
# **`identifier`**             | `string(255)`      | `not null`
# **`media`**                  | `string(255)`      |
# **`metadata_source`**        | `string(255)`      |
# **`north_limit`**            | `float(24)`        |
# **`orthographic_notes`**     | `string(255)`      |
# **`private`**                | `boolean`          |
# **`region`**                 | `string(255)`      |
# **`south_limit`**            | `float(24)`        |
# **`tape_location`**          | `string(255)`      |
# **`title`**                  | `string(255)`      | `not null`
# **`west_limit`**             | `float(24)`        |
# **`created_at`**             | `datetime`         | `not null`
# **`updated_at`**             | `datetime`         | `not null`
# **`access_condition_id`**    | `integer`          |
# **`collector_id`**           | `integer`          | `not null`
# **`field_of_research_id`**   | `integer`          |
# **`operator_id`**            | `integer`          |
# **`university_id`**          | `integer`          |
#
# ### Indexes
#
# * `index_collections_on_access_condition_id`:
#     * **`access_condition_id`**
# * `index_collections_on_collector_id`:
#     * **`collector_id`**
# * `index_collections_on_field_of_research_id`:
#     * **`field_of_research_id`**
# * `index_collections_on_identifier` (_unique_):
#     * **`identifier`**
# * `index_collections_on_operator_id`:
#     * **`operator_id`**
# * `index_collections_on_private`:
#     * **`private`**
# * `index_collections_on_university_id`:
#     * **`university_id`**
#

# rubocop:disable Metrics/ClassLength
class Collection < ApplicationRecord
  include IdentifiableByDoi
  include HasBoundaries

  has_paper_trail
  nilify_blanks

  belongs_to :collector, class_name: 'User'
  belongs_to :operator, class_name: 'User', optional: true
  belongs_to :university, optional: true
  belongs_to :field_of_research, optional: true
  belongs_to :access_condition, optional: true

  has_one :entity, as: :entity

  has_many :grants
  accepts_nested_attributes_for :grants, allow_destroy: true

  has_many :items, dependent: :restrict_with_exception
  accepts_nested_attributes_for :items

  has_many :collection_languages, dependent: :destroy
  has_many :languages, through: :collection_languages, validate: true

  has_many :subject_languages, -> { distinct }, through: :items
  has_many :content_languages, -> { distinct }, through: :items
  has_many :essences, through: :items

  has_many :collection_countries, dependent: :destroy
  has_many :countries, through: :collection_countries, validate: true
  has_many :item_countries, -> { distinct }, through: :items, source: :countries

  has_many :collection_admins, dependent: :destroy, autosave: true
  has_many :admins, through: :collection_admins, validate: true, source: :user, autosave: true

  # require presence of these three fields
  validates :identifier,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: /\A[a-zA-Z0-9_]*\z/, message: "error - only letters and numbers and '_' allowed" },
            length: { in: 3..10 }
  validates :title, presence: true

  validates :north_limit, numericality: { greater_than_or_equal_to: -90, less_then_or_equal_to: 90 }, allow_nil: true
  validates :south_limit, numericality: { greater_than_or_equal_to: -90, less_then_or_equal_to: 90 }, allow_nil: true
  validates :west_limit, numericality: { greater_than_or_equal_to: -180, less_then_or_equal_to: 180 }, allow_nil: true
  validates :east_limit, numericality: { greater_than_or_equal_to: -180, less_then_or_equal_to: 180 }, allow_nil: true

  # Set some defaults
  attribute :has_deposit_form, :boolean, default: false

  bulk = [
    :bulk_edit_append_title, :bulk_edit_append_description, :bulk_edit_append_region,
    :bulk_edit_append_access_narrative, :bulk_edit_append_metadata_source,
    :bulk_edit_append_orthographic_notes, :bulk_edit_append_media, :bulk_edit_append_comments,
    :bulk_edit_append_tape_location, # :bulk_edit_append_grant_identifier,
    :bulk_edit_append_country_ids, :bulk_edit_append_language_ids, :bulk_edit_append_admin_ids
  ]
  attr_reader(*bulk)

  attr_accessor :metadata

  paginates_per 10

  delegate :name, to: :university,        prefix: true, allow_nil: true
  delegate :name, to: :collector,         prefix: true, allow_nil: true
  delegate :sortname, to: :collector,     prefix: true, allow_nil: true
  delegate :name, to: :operator,          prefix: true, allow_nil: true
  delegate :name, to: :access_condition,  prefix: true, allow_nil: true
  delegate :name, to: :field_of_research, prefix: true, allow_nil: true

  before_save :check_complete
  before_save :propagate_collector
  after_save :update_catalog_metadata

  after_commit :reindex_items_if_private_changed, if: :saved_change_to_private?

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
      # we're removing one collection from the users's 'owned' collections
      collector_was.collector = (collector_was.owned_items.count + collector_was.owned_collections.count - 1).positive?
      collector_was.save
    end

    collector.collector = true
    collector.save
  end

  def check_complete
    present = %i[
      identifier title description collector university
      north_limit south_limit east_limit west_limit field_of_research
    ]

    length = %i[languages countries]

    if present.all? { |method| public_send(method).present? } &&
       length.all? { |method| public_send(method).size.positive? } &&
       items.any? { |item| item.originated_on.present? }
      self.complete = true
    end
  end

  def funding_body_names
    # FIXME: for csv output - need to escape
    "\"#{grants.collect { |g| g.funding_body.name }.join(', ')}\""
  end

  def full_grant_identifier(grant)
    if grant.grant_identifier.blank?
      ''
    else
      "#{grant.funding_body&.key_prefix}#{grant.grant_identifier}"
    end
  end

  def update_catalog_metadata
    CatalogMetadataJob.perform_later(self, false)
  end

  searchkick geo_shape: [:bounds], locations: [:location], word_start: [:identifier]

  def self.sortable_columns
    %w[identifier title collector_sortname university_name created_at languages countries]
  end

  def self.search_includes
    %i[collector countries languages university admins]
  end

  def self.search_user_fields
    %i[admin_ids item_admin_ids item_user_ids]
  end

  def self.search_agg_fields
    %i[languages countries collector_name encodingFormat rootCollection]
  end

  def self.search_text_fields
    %i[identifier title description access_narrative region metadata_source orthographic_notes media comments tape_location]
  end

  def self.search_filter_fields
    %i[
      complete private created_at updated_at deposit_form_received
      collector_id operator_id university_id country_ids language_ids admin_ids access_condition_id field_of_research_id funding_body_id
      title_blank description_blank access_narative_blank region_blank metadata_source_blank orthographic_notes_blank
      media_blank comments_blank tape_location_blank grant_identifier_blank
      created_at_blank updated_at_blank
    ]
  end

  def self.search_highlight_fields
    %i[title description]
  end
  scope :search_import, lambda {
                          includes(:university, :collector, :operator, :field_of_research, :languages, :countries, :admins, :grants, items: %i[admins users])
                        }

  def search_data
    data = {
      # Extra things for basic full text search
      record_type: 'Collection',
      university_name:,
      collector_name:,
      collector_sortname:,
      operator_name:,
      field_of_research: field_of_research_name,
      languages: languages.map(&:name).uniq,
      countries: countries.map(&:name).uniq,
      language_codes: languages.map(&:code).uniq,

      # Oni
      encodingFormat: essences.map(&:mimetype).uniq,
      rootCollection: title,

      # Full text plus advanced search
      identifier:,
      title:,
      description:,
      access_narrative:,
      region:,
      metadata_source:,
      orthographic_notes:,
      media:,
      comments:,
      tape_location:,

      complete:,
      private:,

      # Link models for dropdowns and aggs
      collector_id:,
      operator_id:,
      university_id:,
      country_ids: countries.map(&:id).uniq,
      language_ids: languages.map(&:id).uniq,
      admin_ids: admins.map(&:id).uniq,
      item_admin_ids: items.flat_map(&:admin_ids).uniq,
      item_user_ids: items.flat_map(&:user_ids).uniq,
      access_condition_id:,
      field_of_research_id:,
      funding_body_id: grants.map(&:funding_body_id).uniq,
      deposit_form_received:,
      # We don't have this for items so let's use collection created_at
      originated_on: created_at.to_date,

      # Oni
      collection_title: title,
      access_condition_name: access_condition&.name,

      created_at: created_at.to_date,
      updated_at: updated_at.to_date
    }

    if north_limit
      data[:location] = { lon: center_coordinate(0)[:lng], lat: center_coordinate(0)[:lat] }
        if north_limit == south_limit && east_limit == west_limit
          # TODO: SHould this be allowed in the data?
          data[:bounds] = { type: 'point', coordinates: [west_limit, north_limit] }
        else
         data[:bounds] = {
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
      title description
      access_narrative region metadata_source orthographic_notes media comments tape_location
      created_at updated_at
    ]
    blank_fields.each do |field|
      data["#{field}_blank"] = public_send(field).blank?
    end

    data
  end

  def to_param
    identifier
  end

  def full_identifier
    identifier
  end

  def full_path
    # FIX ME
    "http://catalog.paradisec.org.au/collections/#{identifier}"
  end

  def xml_key
    "paradisec.org.au/collection/#{identifier}"
  end

  def citation
    cite = ''
    cite += "#{collector.name} (collector)" if collector
    cite += ", #{items.map(&:originated_on).compact.min.try(:year)}"
    cite += '. ' unless cite == ''
    cite += "<i>#{title}</i>. "
    cite += "Collection #{identifier} at catalog.paradisec.org.au "
    cite += "[#{access_class.capitalize} Access]. "
    cite += doi ? " https://dx.doi.org/#{doi}" : full_path

    cite
  end

  def access_class
    AccessCondition.access_classification(access_condition)
  end

  def coordinates?
    (north_limit && north_limit != 0) ||
      (south_limit && south_limit != 0) ||
      (west_limit && west_limit != 0) ||
      (east_limit && east_limit != 0)
  end

  def center_coordinate(item_counts)
    return unless coordinates?

    long = if east_limit < west_limit
      adjusted_east = east_limit + 360
      center_lng = ((adjusted_east + west_limit) / 2.0) % 360
      center_lng -= 360 if center_lng > 180  # Normalize back to [-180, 180]
      center_lng
    else
             (west_limit + east_limit) / 2
    end

    {
      lat: (north_limit + south_limit) / 2,
      lng: long,
      title:,
      id: identifier,
      items: item_counts[id]
    }
  end

  def csv_countries
    countries.map(&:name).join(';')
  end

  def csv_languages
    languages.map(&:name).join(';')
  end

  def csv_full_grant_identifiers
    grants.map(&method(:full_grant_identifier)).join(';')
  end

  def oai_language
    languages.map(&:name).join(', ')
  end

  def self.map_oai_dc
    { language: :oai_language }
  end

  # OAI-MPH mappings for RIF-CS
  # TODO: should this be in a view of some sort, could we use HAML?
  # rubocop:disable Metrics/MethodLength,Metrics/BlockLength
  def to_rif
    xml = ::Builder::XmlMarkup.new
    xml.registryObjects OAI::Provider::Metadata::Rif.instance.header_specification do
      xml.registryObject 'group' => 'PARADISEC' do
        xml.key xml_key
        xml.originatingSource 'http://catalog.paradisec.org.au', 'type' => 'authoritative'

        xml.collection 'type' => 'collection', 'dateModified' => updated_at.xmlschema do
          xml.dates 'type' => 'dc.created' do
            xml.date created_at.xmlschema, 'type' => 'dateFrom', 'dateFormat' => 'W3CDTF'
          end
          xml.name 'type' => 'primary' do
            xml.namePart title
          end
          xml.description description, 'type' => 'brief'
          xml.rights do
            xml.accessRights access_condition_name
          end
          xml.identifier full_path, 'type' => 'uri'
          xml.location do
            xml.address do
              xml.electronic 'type' => 'url' do
                xml.value full_path
              end
              xml.physical 'type' => 'postalAddress' do
                address = 'PARADISEC Sydney Unit: Sydney Conservatorium of Music, Rm 3019, Building C41, '
                address += 'The University of Sydney, NSW, 2006, Phone +61 2 9351 1279. PARADISEC Melbourne Unit: '
                address += 'School of Languages and Linguistics, University of Melbourne, +61 2 8344 8952 | '
                address += 'PARADISEC Canberra Unit: College of Asia and the Pacific, The Australian National University, +61 2 6125 6115'
                xml.addressPart address, 'type' => 'text'
              end
            end
          end

          xml.relatedObject do
            xml.key collector.xml_key
            xml.relation 'type' => 'hasCollector' do
              xml.url collector.full_path
            end
          end

          xml.relatedObject do
            xml.key 'paradisec.org.au'
            xml.relation 'type' => 'isManagedBy' do
              xml.url 'http://catalog.paradisec.org.au'
            end
          end

          if university
            xml.relatedObject do
              if university.party_identifier
                xml.key university.party_identifier
                xml.relation 'type' => 'isOutputOf'
              else
                xml.key university.xml_key
                xml.relation 'type' => 'isOutputOf' do
                  xml.url university.full_path
                end
              end
            end
          end

          grants.each do |grant|
            xml.relatedObject do
              if grant.grant_identifier.present?
                xml.key full_grant_identifier(grant)
              else
                xml.key grant.funding_body.key_prefix
              end
              xml.relation 'type' => 'isOutputOf'
            end
          end

          languages.each do |language|
            xml.subject language.name, 'type' => 'local'
            xml.subject language.code, 'type' => 'iso639-3'
          end

          xml.subject field_of_research.identifier, 'type' => 'anzsrc-for' if field_of_research

          xml.coverage do
            countries.each do |country|
              xml.spatial country.name, 'type' => 'text'
              xml.spatial country.code, 'type' => 'iso31661'
            end

            if north_limit != 0 || south_limit != 0 || west_limit != 0 || east_limit != 0
              xml.spatial "northlimit=#{north_limit}; southlimit=#{south_limit}; westlimit=#{west_limit}; eastLimit=#{east_limit};", 'type' => 'iso19139dcmiBox'
            end

            unless items.map(&:originated_on).compact.empty?
              xml.temporal do
                if items.map(&:originated_on).compact.min
                  xml.date items.map(&:originated_on).compact.min.xmlschema, 'type' => 'dateFrom', 'dateFormat' => 'W3CDTF'
                end
                if items.map(&:originated_on).compact.max
                  xml.date items.map(&:originated_on).compact.max.xmlschema, 'type' => 'dateTo', 'dateFormat' => 'W3CDTF'
                end
              end
            end
          end

          xml.citationInfo do
            xml.fullCitation ActionController::Base.helpers.strip_tags(citation), 'style' => 'APA'
          end

          languages.each do |language|
            xml.relatedInfo 'type' => 'website' do
              xml.identifier "http://www.ethnologue.com/show_language.asp?code=#{language.code}", 'type' => 'uri'
              xml.title "Ethnologue entry for #{language.name}"
            end
          end
        end
      end

      xml.registryObject 'group' => 'PARADISEC' do
        xml.key collector.xml_key
        xml.originatingSource 'http://catalog.paradisec.org.au', 'type' => 'authoritative'

        xml.party 'type' => 'person', 'dateModified' => updated_at.xmlschema do
          xml.identifier collector.full_path, 'type' => 'uri'
          xml.name 'type' => 'primary' do
            xml.namePart collector.first_name, 'type' => 'given'
            xml.namePart collector.last_name, 'type' => 'family'
          end
          xml.location do
            xml.address do
              xml.electronic 'type' => 'url' do
                xml.value collector.full_path
              end
            end
          end
          xml.relatedObject do
            xml.key 'paradisec.org.au'
            xml.relation 'type' => 'isParticipantIn'
          end
        end
      end

      if university && !university.party_identifier
        xml.registryObject 'group' => 'PARADISEC' do
          xml.key university.xml_key
          xml.originatingSource 'http://catalog.paradisec.org.au', 'type' => 'authoritative'

          xml.party 'type' => 'group', 'dateModified' => updated_at.xmlschema do
            xml.identifier university.full_path, 'type' => 'uri'
            xml.name 'type' => 'primary' do
              xml.namePart university.name, 'type' => 'primary'
            end
            xml.location do
              xml.address do
                xml.electronic 'type' => 'url' do
                  xml.value university.full_path
                end
                xml.physical 'type' => 'streetAddress' do
                  xml.addressPart university.name, 'type' => 'locationDescriptor'
                end
              end
            end
          end
        end
      end
    end
    xml.target!
  end
  # rubocop:enable Metrics/MethodLength,Metrics/BlockLength

  def as_geo_json(url)
    center = center_coordinate({})

    return nil unless center

    item = items.first
    if item
      date = item.originated_on.to_time if item.originated_on
      date ||= item.created_at
    else
      date = created_at
    end

    json = {
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: [center[:lng], center[:lat]]
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
    json[:properties][:languages] = languages.map(&:name_with_code).join(', ') unless languages.empty?
    json[:properties][:countries] = countries.map(&:name_with_code).join(', ') unless countries.empty?
    json[:properties][:license] = access_condition.name if access_condition
    json[:properties][:rights] = access_condition.name if access_condition

    json
  end

  def self.ransackable_attributes(_ = nil)
    %w[
      access_condition_id access_narrative collector_id comments complete created_at deposit_form_received
      description doi east_limit field_of_research_id id identifier media metadata_source north_limit
      operator_id orthographic_notes private region south_limit tape_location title university_id
      updated_at west_limit
    ]
  end

  private

  def reindex_items_if_private_changed
    items.reindex(mode: :async)
  end
end
# rubocop:enable Metrics/ClassLength
