# ## Schema Information
#
# Table name: `collections`
#
# ### Columns
#
# Name                         | Type               | Attributes
# ---------------------------- | ------------------ | ---------------------------
# **`id`**                     | `integer`          | `not null, primary key`
# **`access_narrative`**       | `text(65535)`      |
# **`comments`**               | `text(65535)`      |
# **`complete`**               | `boolean`          |
# **`deposit_form_received`**  | `boolean`          |
# **`description`**            | `text(65535)`      | `not null`
# **`doi`**                    | `string(255)`      |
# **`east_limit`**             | `float(24)`        |
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
# **`created_at`**             | `datetime`         |
# **`updated_at`**             | `datetime`         |
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
# * `index_collections_on_university_id`:
#     * **`university_id`**
#

class Collection < ApplicationRecord
  include IdentifiableByDoi
  include HasBoundaries

  has_paper_trail
  nilify_blanks

  belongs_to :collector, :class_name => "User"
  belongs_to :operator, :class_name => "User", :optional => true
  belongs_to :university, :optional => true
  belongs_to :field_of_research, :optional => true
  belongs_to :access_condition, :optional => true

  has_many :grants
  accepts_nested_attributes_for :grants, allow_destroy: true

  has_many :items, :dependent => :restrict_with_exception
  accepts_nested_attributes_for :items

  has_many :collection_languages, :dependent => :destroy
  has_many :languages, :through => :collection_languages, :validate => true

  has_many :subject_languages, through: :items
  has_many :content_languages, through: :items

  has_many :collection_countries, :dependent => :destroy
  has_many :countries, :through => :collection_countries, :validate => true
  has_many :item_countries, through: :items, source: :countries

  has_many :collection_admins, :dependent => :destroy
  has_many :admins, :through => :collection_admins, :validate => true, :source => :user

  # require presence of these three fields
  validates :identifier, :presence => true, :uniqueness => { case_sensitive: false },
            :format => { :with => /\A[a-zA-Z0-9_]*\z/, :message => "error - only letters and numbers and '_' allowed" }
  validates :title, :presence => true
  validates :collector_id, :presence => true

  validates :north_limit, :numericality => {:greater_than_or_equal_to => -90, :less_then_or_equal_to => 90}, :allow_nil => true
  validates :south_limit, :numericality => {:greater_than_or_equal_to => -90, :less_then_or_equal_to => 90}, :allow_nil => true
  validates :west_limit, :numericality => {:greater_than_or_equal_to => -180, :less_then_or_equal_to => 180}, :allow_nil => true
  validates :east_limit, :numericality => {:greater_than_or_equal_to => -180, :less_then_or_equal_to => 180}, :allow_nil => true

  bulk = [
    :bulk_edit_append_title, :bulk_edit_append_description, :bulk_edit_append_region,
    :bulk_edit_append_access_narrative, :bulk_edit_append_metadata_source,
    :bulk_edit_append_orthographic_notes, :bulk_edit_append_media, :bulk_edit_append_comments,
    :bulk_edit_append_tape_location,# :bulk_edit_append_grant_identifier,
    :bulk_edit_append_country_ids, :bulk_edit_append_language_ids, :bulk_edit_append_admin_ids
  ]
  attr_reader(*bulk)

  attr_accessor :metadata

  paginates_per 10

  delegate :name, :to => :university,        :prefix => true, :allow_nil => true
  delegate :name, :to => :collector,         :prefix => true, :allow_nil => true
  delegate :sortname, :to => :collector,     :prefix => true, :allow_nil => true
  delegate :name, :to => :operator,          :prefix => true, :allow_nil => true
  delegate :name, :to => :access_condition,  :prefix => true, :allow_nil => true
  delegate :name, :to => :field_of_research, :prefix => true, :allow_nil => true

  before_save :check_complete
  before_save :propagate_collector

  def has_default_map_boundaries?
    if (north_limit == 80.0) && (south_limit == -80.0) && (east_limit == -40.0) && (west_limit == -20.0)
      true
    else
      false
    end
  end

  def propagate_collector
    if collector_id_changed?
      unless collector_id_was.nil?
        collector_was = User.find(collector_id_was)
        # we're removing one collection from the users's 'owned' collections
        collector_was.collector = (collector_was.owned_items.count + collector_was.owned_collections.count - 1) > 0
        collector_was.save
      end
      collector.collector = true
      collector.save
    end
  end

  def check_complete
    present = [
      :identifier, :title, :description, :collector, :university,
      :north_limit, :south_limit, :east_limit, :west_limit,
      :field_of_research
    ]

    length = [
      :languages, :countries
    ]

    if present.all? {|method| self.public_send(method).present? } and length.all? {|method| self.public_send(method).size > 0} and items.any? {|item| item.originated_on.present?}
      self.complete = true
    end
  end

  def funding_body_names
    #FIXME: for csv output - need to escape
    '"'+"#{grants.collect{|g| g.funding_body.name}.join(', ')}"+'"'
  end

  def full_grant_identifier(grant)
    if grant.grant_identifier.blank?
      ""
    else
      "#{grant.funding_body.key_prefix if grant.funding_body}#{grant.grant_identifier}"
    end
  end

  def self.sortable_columns
    %w{identifier title collector_sortname university_name created_at sort_language sort_country}
  end

  searchable(
    include: [
      :university, :collector, :operator, :field_of_research, :languages, :countries, :admins,
      items: [:admins, :users]
    ]
  ) do
    # Things we want to perform full text search on
    text :title
    text :identifier, :as => :identifier_textp
    text :identifier2 do
      identifier
    end
    text :university_name
    text :collector_name
    text :region
    text :description
    text :operator_name
    text :field_of_research do
      field_of_research_name
    end
    text :languages do
      languages.map(&:name)
    end
    text :countries do
      countries.map(&:name)
    end
    text :access_narrative
    text :metadata_source
    text :orthographic_notes
    text :media
    text :comments
    text :tape_location

    # Link models for faceting or dropdowns
    integer :language_ids, :references => Language, :multiple => true
    integer :collector_id, :references => User
    integer :operator_id, :references => User
    integer :country_ids, :references => Country, :multiple => true
    integer :university_id, :references => University
    integer :field_of_research_id, :references => FieldOfResearch
    # integer :funding_body_ids, :references => FundingBody, :multiple => true
    integer :admin_ids, :references => User, :multiple => true
    integer :access_condition_id, :references => AccessCondition

    # Things we want to sort or use :with on
    integer :id
    integer :item_admin_ids, :references => User, :multiple => true do
      items.flat_map(&:admin_ids).uniq
    end
    integer :item_user_ids, :references => User, :multiple => true do
      items.flat_map(&:user_ids).uniq
    end
    string :title
    string :identifier
    string :university_name
    string :collector_name
    string :collector_sortname
    string :region
    string :languages, :multiple => true do
      languages.map(&:name)
    end
    string :language_codes, :multiple => true do
      languages.map(&:code)
    end
    string :countries, :multiple => true do
      countries.map(&:name)
    end
    string :country_codes, :multiple => true do
      countries.map(&:code)
    end
    string :sort_language do
      languages.order('name ASC').map(&:name).join(',')
    end
    string :sort_country do
      countries.order('name ASC').map(&:name).join(',')
    end
    float :north_limit
    float :south_limit
    float :west_limit
    float :east_limit
    boolean :complete
    boolean :private
    boolean :deposit_form_received
    time :created_at
    time :updated_at

    # Things we want to check blankness of
    blank_fields = [:title, :description, :region, :access_narrative, :metadata_source, :orthographic_notes, :media, :created_at, :updated_at, :comments, :tape_location]
    blank_fields.each do |f|
      boolean "#{f}_blank".to_sym do
        self.public_send(f).blank?
      end
    end
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

  # for DOI relationship linking: nil <- Collection <- Item <- Essence
  def parent
    nil
  end

  def citation
    cite = ""
    if collector
      cite += "#{collector.name} (collector)"
    end
    cite += ", #{items.map(&:originated_on).compact.min.try(:year)}"
    cite += '. ' unless cite == ""
    cite += "<i>#{title}</i>. "
    cite += "Collection #{identifier} at catalog.paradisec.org.au "
    cite += "[#{access_class.capitalize} Access]. "
    if doi
      cite += " https://dx.doi.org/#{doi}"
    else
      cite += "#{full_path}"
    end
    cite
  end

  def access_class
    AccessCondition.access_classification(access_condition)
  end

  def has_coordinates
    (north_limit && north_limit != 0) ||
    (south_limit && south_limit != 0) ||
    (west_limit && west_limit != 0) ||
    (east_limit && east_limit != 0)
  end

  def center_coordinate(item_counts)
    if has_coordinates
      if east_limit < west_limit
        long = 180 + (west_limit + east_limit) / 2
      else
        long = (west_limit + east_limit) / 2
      end
      {
        :lat => (north_limit + south_limit) / 2,
        :lng => long,
        :title => title,
        :id => identifier,
        :items => item_counts[id],
      }
    end
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
    {:language => :oai_language}
  end

  # OAI-MPH mappings for RIF-CS
  # TODO: should this be in a view of some sort, could we use HAML?
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
                xml.addressPart 'PARADISEC Sydney Unit: Sydney Conservatorium of Music, Rm 3019, Building C41, The University of Sydney, NSW, 2006, Phone +61 2 9351 1279. PARADISEC Melbourne Unit: School of Languages and Linguistics, University of Melbourne, +61 2 8344 8952 | PARADISEC Canberra Unit: College of Asia and the Pacific, The Australian National University, +61 2 6125 6115', 'type' => 'text'
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

          if field_of_research
            xml.subject field_of_research.identifier, 'type' => 'anzsrc-for'
          end

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
end
