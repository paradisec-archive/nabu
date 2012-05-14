class Item < ActiveRecord::Base
  delegate :url_helpers, :to => 'Rails.application.routes'
  has_paper_trail
  nilify_blanks

  belongs_to :collection
  belongs_to :collector, :class_name => 'User'
  belongs_to :operator, :class_name => 'User'
  belongs_to :university
  belongs_to :access_condition
  belongs_to :discourse_type

  has_many :item_countries, :dependent => :destroy
  has_many :countries, :through => :item_countries, :validate => true

  has_many :item_subject_languages, :dependent => :destroy
  has_many :subject_languages, :through => :item_subject_languages, :source => :language, :validate => true

  has_many :item_content_languages, :dependent => :destroy
  has_many :content_languages, :through => :item_content_languages, :source => :language, :validate => true

  has_many :item_admins, :dependent => :destroy
  has_many :admins, :through => :item_admins, :validate => true, :source => :user

  has_many :item_agents, :dependent => :destroy
  has_many :agents, :through => :item_agents, :validate => true, :source => :user

  has_many :essences, :dependent => :restrict
  has_many :comments, :as => :commentable, :dependent => :destroy

  validates :identifier, :presence => true, :uniqueness => {:scope => [:collection_id, :identifier]}
  validates :title, :description, :presence => true
  validates :collector_id, :presence => true
# FIXME: possibly re-activate these after import
#  validates :region, :presence => true
#  validates :university_id, :operator_id, :presence => true
#  validates :latitude, :longitude, :zoom, :presence => true
#  validates :subject_language_id, :content_language_id, :discourse_type_id, :presence => true
#  validates :originated_on, :presence => true
  validates :latitude, :numericality => {:greater_than_or_equal_to => -90, :less_then_or_equal_to => 90}
  validates :longitude, :numericality => {:greater_than_or_equal_to => -180, :less_then_or_equal_to => 180}
  validates :zoom, :numericality => {:only_integer => true, :greater_than_or_equal_to => 0, :less_than => 22}

  attr_accessible :identifier, :title, :owned, :url, :description, :region,
                  :latitude, :longitude, :zoom,
                  :collector_id, :university_id, :operator_id,
                  :country_ids,
                  :content_language_ids, :subject_language_ids,
                  :admin_ids, :item_agents_attributes,
                  :access_condition_id,
                  :access_narrative, :private,
                  :admin_comment,
                  :originated_on, :language,
                  :dialect, :discourse_type_id,
                  :metadata_exportable, :born_digital, :tapes_returned,
                  :original_media, :ingest_notes, :tracking

  accepts_nested_attributes_for :item_agents, :allow_destroy => true, :reject_if => :all_blank

  delegate :name, :to => :collector, :prefix => true, :allow_nil => true
  delegate :name, :to => :operator, :prefix => true, :allow_nil => true
  delegate :name, :to => :university, :prefix => true, :allow_nil => true
  delegate :name, :to => :discourse_type, :prefix => true, :allow_nil => true
  delegate :name, :to => :access_condition, :prefix => true, :allow_nil => true

  paginates_per 10

  after_initialize :prefill


  def full_identifier
    collection.identifier + '-' + identifier
  end

  def essence_types
    essences.map(&:type).uniq
  end

  def prefill
    return unless collection
    return unless new_record?

    self.university_id ||= collection.university_id
    self.collector_id ||= collection.collector_id
    self.operator_id ||= collection.operator_id

    self.region ||= collection.region
    self.latitude ||= collection.latitude
    self.longitude ||= collection.longitude
    self.zoom ||= collection.zoom
    if self.item_countries.empty?
      collection.collection_countries.each do |collection_country|
        self.item_countries.build :country_id => collection_country.country_id
      end
    end
    if self.item_subject_languages.empty?
      collection.collection_languages.each do |collection_language|
        self.item_subject_languages.build :language_id => collection_language.language_id
      end
    end
    if self.item_content_languages.empty?
      collection.collection_languages.each do |collection_language|
        self.item_content_languages.build :language_id => collection_language.language_id
      end
    end

    self.access_condition_id ||= collection.access_condition_id
    self.access_narrative ||= collection.access_narrative
    if self.item_admins.empty?
      collection.collection_admins.each do |collection_admin|
        self.item_admins.build :user_id => collection_admin.user_id
      end
    end
  end

  def self.sortable_columns
    %w{identifier title university_name collector_name updated_at language}
  end
  searchable do
    # Things we want to perform full text search on
    text :title
    text :identifier
    text :collection_identifier do
      collection.identifier
    end
    text :identifier
    text :collector_name
    text :university_name
    text :operator_name
    text :description
    text :language
    text :dialect
    text :region
    text :discourse_type_name
    text :access_condition_name
    text :access_narrative
    text :ingest_notes
    text :tracking
    text :original_media
    text :content_languages do
      content_languages.map(&:name)
    end
    text :subject_languages do
      subject_languages.map(&:name)
    end
    text :countries do
      countries.map(&:name)
    end

    # Things we want to sort or use :with on
    integer :id
    string :title
    string :identifier
    string :university_name
    string :collector_name
    string :region
    string :identifier
    string :collection_identifier do
      collection.identifier
    end
    boolean :private
    date :originated_on
    float :latitude
    float :longitude
    integer :zoom
    boolean :metadata_exportable
    boolean :born_digital
    boolean :tapes_returned
    date :received_on
    date :digitised_on
    date :created_at
    date :updated_at
    string :content_languages, :multiple => true do
      content_languages.map(&:name)
    end
    string :subject_languages, :multiple => true do
      subject_languages.map(&:name)
    end
    string :countries, :multiple => true do
      countries.map(&:name)
    end

    # Link models for faceting
    integer :university_id, :references => University
    integer :content_language_ids, :references => Language, :multiple => true
    integer :subject_language_ids, :references => Language, :multiple => true
    integer :country_ids, :references => Country, :multiple => true
  end

  def next_item
    Item.where(:collection_id => self.collection).order(:identifier).where('identifier > ?', self.identifier).first
  end

  def prev_item
    Item.where(:collection_id => self.collection).order(:identifier).where('identifier < ?', self.identifier).first
  end

  def citation
    cite = "#{collector.name} (recorder)"
    cite += " #{originated_on.year}" if originated_on
    cite += '; '
    cite += title
    cite += ','
    last = essence_types.length - 1
    essence_types.each_with_index do |type, index|
      cite += type
      if index != last
        cite += "/"
      end
    end
    cite += " #{url || url_helpers.item_url(self, :host => 'paradisec.org.au')}"
    cite += " #{Date.today}."
    cite
  end


  # OAI-MPH mappings
  # If we need to later on we can generate the XML directly
  # TODO
  # - The <request> header doesn't have the params to the request as XML attributes
  def to_oai_dc
    xml = ::Builder::XmlMarkup.new
    xml.tag!(
      'oai_dc',
      'xmlns:oai_dc'  => 'http://www.openarchives.org/OAI/2.0/oai_dc/',
      'xmlns:dc'      => 'http://purl.org/dc/elements/1.1/',
      'xmlns:xsi'     => 'http://www.w3.org/2001/XMLSchema-instance',
      'xmlns:dcterms' => 'http://purl.org/dc/terms/',
      'xmlns:olac'    => 'http://www.language-archives.org/OLAC/1.1/',
      'xsi:schemaLocation' => %{http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd http://www.language-archives.org/OLAC/1.1/dcterms.xsd http://www.language-archives.org/OLAC/1.1/ http://www.language-archives.org/OLAC/1.1/olac.xsd}
    ) do
      xml.tag! 'dc:title', title

      xml.tag! 'dc:identifier', full_identifier
      xml.tag! 'dc:identifier', url_helpers.item_url(self, :host => 'paradisec.org.au'), 'xsi:type' => 'dcterms:URI' if owned?
      xml.tag! 'dc:identifier', url if url?

      xml.tag! 'dc:subject', 'xsi:type' => 'olac:linguistic-field', 'olac:code' => 'language_documentation'
      xml.tag! 'dcterms:created', originated_on, 'xsi:type' => 'dcterms:W3CDTF'
      xml.tag! 'dc:date', originated_on, 'xsi:type' => 'dcterms:W3CDTF'

      essences.each do |essence|
        xml.tag! 'dcterms:tableOfContents', essence.filename
      end

      item_agents.each do |agent|
        xml.tag! 'dc:contributor', agent.user.name, 'xsi:type' => 'olac:role', 'olac:code' => 'recorder'
      end

      subject_languages.each do |language|
        xml.tag! 'dc:subject', 'xsi:type' => 'olac:language', 'olac:code' => language.code
      end
      content_languages.each do |language|
        xml.tag! 'dc:content', 'xsi:type' => 'olac:language', 'olac:code' => language.code
      end
      # TODO bring this back
      format = ""
      #format += "Digitised: #{born_digital? ? 'yes' : 'no'}"
      format += "\nMedia: #{original_media}" unless original_media.blank?
      format += "\nAudio Notes: #{ingest_notes}" unless ingest_notes.blank?
      xml.tag! 'dc:format', format
      countries.each do |country|
        xml.tag! 'dc:coverage', country.code, 'xsi:type' => 'dcterms:ISO3166'
      end
      # TODO GEO
      #<dc:coverage xsi:type="dcterms:Box">northlimit=2.083; southlimit=1.006; westlimit=108.905; eastlimit=109.711</dc:coverage>
      # TODO
      # old item_type table
      # <dc:type xsi:type="olac:linguistic-type" olac:code="primary_text"/>
      # <dc:subject xsi:type="olac:linguistic-field" olac:code="text_and_corpus_linguistics"/>
      # <dc:type xsi:type="olac:discourse-type" olac:code="singing"/>
      # <dc:type xsi:type="dcterms:DCMIType">Sound</dc:type>
      # <dc:type xsi:type="dcterms:DCMIType">MovingImage</dc:type>
      xml.tag! 'dcterms:accessRights', access_condition.name
      xml.tag! 'dc:rights', access_condition.name
      xml.tag! 'dcterms:bibliographicCitation', citation
      xml.tag! 'dc:description', (description + ". Language as given: #{language}")
    end
    xml.target!
  end
end
