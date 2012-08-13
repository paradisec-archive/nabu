class Collection < ActiveRecord::Base
  has_paper_trail
  nilify_blanks

  belongs_to :collector, :class_name => "User"
  belongs_to :operator, :class_name => "User"
  belongs_to :university
  belongs_to :field_of_research
  belongs_to :access_condition
  belongs_to :funding_body

  has_many :items, :dependent => :restrict
  has_many :collection_languages, :dependent => :destroy
  has_many :languages, :through => :collection_languages, :validate => true

  has_many :collection_countries, :dependent => :destroy
  has_many :countries, :through => :collection_countries, :validate => true

  has_many :collection_admins, :dependent => :destroy
  has_many :admins, :through => :collection_admins, :validate => true, :source => :user

  # require presence of these three fields
  validates :identifier, :presence => true, :uniqueness => true,
            :format => { :with => /^[a-zA-Z0-9_]*$/, :message => "error - only letters and numbers and '_' allowed" }
  validates :title, :presence => true
  validates :collector_id, :presence => true

  validates :latitude, :numericality => {:greater_than_or_equal_to => -90, :less_then_or_equal_to => 90}, :allow_nil => true
  validates :longitude, :numericality => {:greater_than_or_equal_to => -180, :less_then_or_equal_to => 180}, :allow_nil => true
  validates :zoom, :numericality => {:only_integer => true, :greater_than_or_equal_to => 0, :less_than => 22}, :allow_nil => true

  attr_reader :bulk_edit_append_country_ids, :bulk_edit_append_language_ids, :bulk_edit_append_admin_ids

  attr_accessible :identifier, :title, :description, :region,
                  :latitude, :longitude, :zoom,
                  :collector_id, :operator_id, :university_id, :field_of_research_id,
                  :funding_body_id, :grant_identifier,
                  :language_ids, :country_ids, :admin_ids,
                  :access_condition_id,
                  :access_narrative, :metadata_source, :orthographic_notes, :media, :comments,
                  :complete, :private, :tape_location, :deposit_form_received,
                  :bulk_edit_append_country_ids, :bulk_edit_append_language_ids, :bulk_edit_append_admin_ids

  paginates_per 10

  delegate :name, :to => :university, :prefix => true, :allow_nil => true
  delegate :name, :to => :collector, :prefix => true, :allow_nil => true
  delegate :name, :to => :operator, :prefix => true, :allow_nil => true
  delegate :name, :to => :access_condition, :prefix => true, :allow_nil => true

  def self.sortable_columns
    %w{identifier title university_name collector_name created_at}
  end

  searchable do
    # Things we want to perform full text search on
    text :title
    text :identifier, :as => :code_textp
    text :university_name
    text :collector_name
    text :region
    text :description
    text :operator_name
    text :access_condition_name
    text :field_of_research do
      field_of_research.name
    end
    text :grant_identifier
    text :funding_body do
      funding_body.name
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

    # Link models for faceting
    integer :collector_id, :references => User
    integer :language_ids, :references => Language, :multiple => true
    integer :country_ids, :references => Country, :multiple => true

    # Things we want to sort or use :with on
    integer :id
    string :title
    string :identifier
    string :university_name
    string :collector_name
    string :region
    string :languages, :multiple => true do
      languages.map(&:name)
    end
    string :countries, :multiple => true do
      countries.map(&:name)
    end
    float :latitude
    float :longitude
    integer :zoom
    boolean :complete
    boolean :private
    boolean :deposit_form_received
    time :created_at

    # Things we want to check blankness of
    blank_fields = [:title, :description, :region, :access_narrative, :metadata_source, :orthographic_notes, :media, :created_at, :updated_at, :comments, :tape_location, :grant_identifier]
    blank_fields.each do |f|
      boolean "#{f}_blank".to_sym do
        self.send(f).blank?
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

  def citation
    cite = ""
    if collector
      cite += "#{collector.name} (collector)"
    end
    cite += ", #{items.map(&:originated_on).min.year}"
    cite += '; ' unless cite == ""
    cite += "<i>#{sanitize(title)}</i>, "
    cite += "Digital collection managed by PARADISEC. "
    cite += " #{full_path},"
    cite += " #{Date.today}."
    cite
  end

  def oai_language
    languages.map(&:name).join(', ')
  end

  def self.map_oai_dc
    {:language => :oai_language}
  end

  # OAI-MPH mappings for RIF-CS
  def to_rif
    xml = ::Builder::XmlMarkup.new
    xml.tag! 'registryObjects', OAI::Provider::Metadata::Rif.instance.header_specification do
      xml.tag! 'registryObject', 'group' => 'PARADISEC'
      xml.tag! 'key', full_path
      xml.tag! 'originatingSource', 'http://catalog.paradisec.org.au', 'type' => 'authoritative'

      xml.tag! 'collection', 'type' => 'collection', 'dateModified' => updated_at do

        xml.tag! 'name', 'type' => 'primary', 'field_id' => 'name_1', 'tab_id' => 'name' do
          xml.tag! 'namePart', title, 'type' => '', 'field_id' => 'name_1_namePart_1', 'tab_id' => 'name'
        end
        xml.tag! 'description', description, 'type' => 'brief', 'field_id' => 'description_1', 'tab_id' => 'description'
        xml.tag! 'rights', 'field_id' => 'rights_1', 'tab_id' => 'rights' do
          xml.tag! 'accessRights', access_condition_name, 'field_id' => 'rights_1_accessRights_1', 'tab_id' => 'rights'
        end
        xml.tag! 'identifier', full_path, 'type' => 'uri', 'field_id' => 'identifier_1', 'tab_id' => 'identifier'
        xml.tag! 'location', 'field_id' => 'location_1', 'tab_id' => 'location' do
          xml.tag! 'address', 'field_id' => 'location_1_address_1', 'tab_id' => 'location' do
            xml.tag! 'electronic', 'type' => 'url', 'field_id' => 'location_1_address_1_electronic_1', 'tab_id' => 'location' do
              xml.tag! 'value', full_path, 'field_id' => 'location_1_address_1_electronic_1_value_1', 'tab_id' => 'location'
            end
          end
        end

        xml.tag! 'relatedObject', 'field_id' => 'relatedObject_1', 'tab_id' => 'relatedObject' do
          xml.tag! 'key', collector.full_path, 'roclass' => 'Party', 'field_id' => 'relatedObject_1_key_1', 'tab_id' => 'relatedObject'
          xml.tag! 'relation', 'type' => 'hasCollector', 'field_id' => 'relatedObject_1_relation_1', 'tab_id' => 'relatedObject' do
            xml.tag! 'url', 'field_id' => 'relatedObject_1_relation_1_url_1', 'tab_id' => 'relatedObject'
          end
        end

        xml.tag! 'relatedObject', 'field_id' => 'relatedObject_3', 'tab_id' => 'relatedObject' do
          if university.party_identifier
            xml.tag! 'key', university.party_identifier, 'roclass' => 'Party', 'field_id' => 'relatedObject_3_key_1', 'tab_id' => 'relatedObject'
          else
            xml.tag! 'key', university.name, 'roclass' => 'Party', 'field_id' => 'relatedObject_3_key_1', 'tab_id' => 'relatedObject'
          end
          xml.tag! 'relation', 'type' => 'isOutputOf', 'field_id' => 'relatedObject_3_relation_1', 'tab_id' => 'relatedObject' do
            xml.tag! 'url', 'field_id' => 'relatedObject_3_relation_1_url_1', 'tab_id' => 'relatedObject'
          end
        end

        languages.each do |language|
          xml.tag! 'subject', language.name, 'type' => 'local', 'field_id' => 'subject_1', 'tab_id' => 'subject'
          xml.tag! 'subject', language.code, 'type' => 'iso639-3', 'field_id' => 'subject_2', 'tab_id' => 'subject'
        end

        countries.each do |country|
          xml.tag! 'coverage', 'field_id' => 'coverage_1', 'tab_id' => 'coverage' do
            xml.tag! 'spatial', country.name, 'type' => 'text', 'field_id' => 'coverage_1_spatial_1', 'tab_id' => 'coverage'
            xml.tag! 'spatial', country.code, 'type' => 'iso31661', 'field_id' => 'coverage_1_spatial_2', 'tab_id' => 'coverage'
          end
        end

        xml.tag! 'coverage', 'field_id' => 'coverage_2', 'tab_id' => 'coverage' do
          xml.tag! 'temporal', items.map(&:originated_on).min, 'type' => 'dateFrom', 'dateFormat' => 'UTC', 'field_id' => 'coverage_2_temporal_1_date_1', 'tab_id' => 'coverage'
          xml.tag! 'temporal', items.map(&:originated_on).max, 'type' => 'dateTo', 'dateFormat' => 'UTC', 'field_id' => 'coverage_2_temporal_1_date_2', 'tab_id' => 'coverage'
        end

        xml.tag! 'citationInfo', 'field_id' => 'citationInfo_1', 'tab_id' => 'citationInfo' do
          xml.tag! 'fullCitation', citation, 'style' => 'APA', 'field_id' => 'citationInfo_1_fullCitation_1', 'tab_id' => 'citationInfo'
        end

        xml.tag! 'relatedInfo', 'type' => 'website', 'field_id' => 'relatedInfo_1', 'tab_id' => 'relatedInfo' do
          xml.tag! 'identifier', "http://www.ethnologue.com/show_language.asp?code=#{languages.first.code}", 'field_id' => 'relatedInfo_1_identifier_1', 'tab_id' => 'relatedInfo'
          xml.tag! 'title', "Ethnologue entry for #{languages.first.name}", 'field_id' => 'relatedInfo_1_title_1', 'tab_id' => 'relatedInfo'
          xml.tag! 'notes', 'field_id' => 'relatedInfo_1_notes_1', 'tab_id' => 'relatedInfo'
        end
      end

    end
    xml.target!
  end

end
