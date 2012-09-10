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

  validates :north_limit, :numericality => {:greater_than_or_equal_to => -90, :less_then_or_equal_to => 90}, :allow_nil => true
  validates :south_limit, :numericality => {:greater_than_or_equal_to => -90, :less_then_or_equal_to => 90}, :allow_nil => true
  validates :west_limit, :numericality => {:greater_than_or_equal_to => -180, :less_then_or_equal_to => 180}, :allow_nil => true
  validates :east_limit, :numericality => {:greater_than_or_equal_to => -180, :less_then_or_equal_to => 180}, :allow_nil => true

  bulk = [
    :bulk_edit_append_title, :bulk_edit_append_description, :bulk_edit_append_region,
    :bulk_edit_append_access_narrative, :bulk_edit_append_metadata_source,
    :bulk_edit_append_orthographic_notes, :bulk_edit_append_media, :bulk_edit_append_comments,
    :bulk_edit_append_tape_location, :bulk_edit_append_grant_identifier,
    :bulk_edit_append_country_ids, :bulk_edit_append_language_ids, :bulk_edit_append_admin_ids
  ]
  attr_reader *bulk

  attr_accessible :identifier, :title, :description, :region,
                  :north_limit, :south_limit, :west_limit, :east_limit,
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
    float :north_limit
    float :south_limit
    float :west_limit
    float :east_limit
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

  def xml_key
    "paradisec.org.au/collection/#{identifier}"
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

  def has_coordinates
    (north_limit && north_limit != 0) &&
    (south_limit && south_limit != 0) &&
    (west_limit && west_limit != 0) &&
    (east_limit && east_limit != 0)
  end

  def csv_countries
    countries.map(&:name).join(';')
  end

  def csv_languages
    languages.map(&:name).join(';')
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
    xml.registryObjects OAI::Provider::Metadata::Rif.instance.header_specification do
      xml.registryObject 'group' => 'PARADISEC' do
        xml.key xml_key
        xml.originatingSource 'http://catalog.paradisec.org.au', 'type' => 'authoritative'

        xml.collection 'type' => 'collection', 'dateModified' => updated_at.xmlschema do
          xml.name 'type' => 'primary' do
            xml.namePart title
          end
          xml.description description, 'type' => 'brief'
          xml.rights do
            xml.accessRights access_condition_name
          end
          xml.identifier xml_key, 'type' => 'uri'
          xml.location do
            xml.address do
              xml.electronic 'type' => 'url' do
                xml.value full_path
              end
              xml.physical 'type' => 'postalAddress' do
                xml.addressPart 'PARADISEC Sydney, Department of Linguistics, second floor Transient Building F12, Fisher Road, The University of Sydney, Camperdown Campus, NSW 2006, AUSTRALIA, Phone: +61 2 9351 2002', 'type' => 'text'
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
              xml.key university.xml_key
              xml.relation 'type' => 'isOutputOf' do
                xml.url university.full_path
              end
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
                  xml.date items.map(&:originated_on).compact.min.xmlschema, 'type' => 'dateFrom', 'dateFormat' => 'UTC'
                end
                if items.map(&:originated_on).compact.max
                  xml.date items.map(&:originated_on).compact.max.xmlschema, 'type' => 'dateTo', 'dateFormat' => 'UTC'
                end
              end
            end
          end

          xml.citationInfo do
            xml.fullCitation citation, 'style' => 'APA'
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
          xml.identifier collector.xml_key, 'type' => 'local'
          xml.name 'type' => 'primary' do
            xml.namePart collector.first_name, 'type' => 'given'
            xml.namePart collector.last_name, 'type' => 'family'
          end
          xml.location do
            xml.address do
              xml.electronic 'type' => 'url' do
                xml.value collector.full_path
              end
              xml.physical 'type' => 'postalAddress' do
                xml.addressPart collector.name + ' c/o PARADISEC, Department of Linguistics, The University of Sydney', 'type' => 'text'
              end
            end
          end
        end
      end

      if university
        xml.registryObject 'group' => 'PARADISEC' do
          xml.key university.xml_key
          xml.originatingSource 'http://catalog.paradisec.org.au', 'type' => 'authoritative'

          xml.party 'type' => 'group', 'dateModified' => updated_at.xmlschema do
            xml.identifier university.xml_key, 'type' => 'local'
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
