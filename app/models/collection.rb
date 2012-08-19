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

  bulk = [
    :bulk_edit_append_title, :bulk_edit_append_description, :bulk_edit_append_region,
    :bulk_edit_append_access_narrative, :bulk_edit_append_metadata_source,
    :bulk_edit_append_orthographic_notes, :bulk_edit_append_media, :bulk_edit_append_comments,
    :bulk_edit_append_tape_location, :bulk_edit_append_grant_identifier,
    :bulk_edit_append_country_ids, :bulk_edit_append_language_ids, :bulk_edit_append_admin_ids
  ]
  attr_reader *bulk

  attr_accessible :identifier, :title, :description, :region,
                  :latitude, :longitude, :zoom,
                  :collector_id, :operator_id, :university_id, :field_of_research_id,
                  :funding_body_id, :grant_identifier,
                  :language_ids, :country_ids, :admin_ids,
                  :access_condition_id,
                  :access_narrative, :metadata_source, :orthographic_notes, :media, :comments,
                  :complete, :private, :tape_location, :deposit_form_received,
                  *bulk

  paginates_per 10

  delegate :name, :to => :university,        :prefix => true, :allow_nil => true
  delegate :name, :to => :collector,         :prefix => true, :allow_nil => true
  delegate :name, :to => :operator,          :prefix => true, :allow_nil => true
  delegate :name, :to => :access_condition,  :prefix => true, :allow_nil => true
  delegate :name, :to => :funding_body,      :prefix => true, :allow_nil => true
  delegate :name, :to => :field_of_research, :prefix => true, :allow_nil => true

  def full_grant_identifier
    "#{funding_body.key_prefix if funding_body}#{grant_identifier}"
  end

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
      field_of_research_name
    end
    text :grant_identifier
    text :funding_body do
      funding_body_name
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
    integer :funding_body_id, :references => FundingBody
    integer :admin_ids, :references => User, :multiple => true

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
    cite += ", #{items.map(&:originated_on).compact.min.try(:year)}"
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
      xml.tag! 'registryObject', 'group' => 'PARADISEC' do
        xml.tag! 'key', full_path
        xml.tag! 'originatingSource', 'http://catalog.paradisec.org.au', 'type' => 'authoritative'

        xml.tag! 'collection', 'type' => 'collection', 'dateModified' => updated_at do

          xml.tag! 'name', 'type' => 'primary' do
            xml.tag! 'namePart', title
          end
          xml.tag! 'description', description, 'type' => 'brief'
          xml.tag! 'rights' do
            xml.tag! 'accessRights', access_condition_name
          end
          xml.tag! 'identifier', full_path, 'type' => 'uri'
          xml.tag! 'location' do
            xml.tag! 'address' do
              xml.tag! 'electronic', 'type' => 'url' do
                xml.tag! 'value', full_path
              end
              xml.tag! 'physical', 'type' => 'postalAddress' do
                xml.tag! 'addressPart', 'PARADISEC Sydney, Department of Linguistics, second floor Transient Building F12, Fisher Road, The University of Sydney, Camperdown Campus, NSW 2006, AUSTRALIA, Phone: +61 2 9351 2002', 'type' => 'text'
              end
            end
          end

          xml.tag! 'relatedObject' do
            xml.tag! 'key', collector.full_path
            xml.tag! 'relation', 'type' => 'hasCollector' do
              xml.tag! 'description', 'Collector'
              xml.tag! 'url'
            end
          end

          xml.tag! 'relatedObject' do
            xml.tag! 'key', 'paradisec.org.au'
            xml.tag! 'relation', 'type' => 'isManagedBy' do
              xml.tag! 'url'
            end
          end

          if university
            xml.tag! 'relatedObject' do
              if university.party_identifier
                xml.tag! 'key', university.party_identifier
              else
                xml.tag! 'key', university.full_path
              end
              xml.tag! 'relation', 'type' => 'isOutputOf' do
                xml.tag! 'description', university.name
                xml.tag! 'url', university.full_path
              end
            end
          end

          languages.each do |language|
            xml.tag! 'subject', language.name, 'type' => 'local'
            xml.tag! 'subject', language.code, 'type' => 'iso639-3'
          end

          xml.tag! 'coverage' do
            countries.each do |country|
              xml.tag! 'spatial', country.name, 'type' => 'text'
              xml.tag! 'spatial', country.code, 'type' => 'iso31661'
            end

            # FIXME: geographic coordinates not correct
            xml.tag! 'spatial', 'type' => 'iso19139dcmiBox', 'northlimit' => latitude, 'southlimit' => longitude, 'westlimit' => latitude, 'eastLimit' => longitude

            xml.tag! 'temporal' do
              xml.tag! 'date', items.map(&:originated_on).compact.min, 'type' => 'dateFrom', 'dateFormat' => 'UTC'
              xml.tag! 'date', items.map(&:originated_on).compact.max, 'type' => 'dateTo', 'dateFormat' => 'UTC'
            end
          end

          xml.tag! 'citationInfo' do
            xml.tag! 'fullCitation', citation, 'style' => 'APA'
          end

          xml.tag! 'relatedInfo', 'type' => 'website' do
            xml.tag! 'identifier', "http://www.ethnologue.com/show_language.asp?code=#{languages.first.try(:code)}", 'type' => 'uri'
            xml.tag! 'title', "Ethnologue entry for #{languages.first.try(:name)}"
          end
        end
      end
    end
    xml.target!
  end

end
