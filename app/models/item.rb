class Item < ActiveRecord::Base
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
  has_many :essences, :dependent => :destroy

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

  attr_accessible :identifier, :title, :url, :description, :region,
                  :latitude, :longitude, :zoom,
                  :collector_id, :university_id, :operator_id,
                  :countries_ids,
                  :content_languages_ids, :subject_languages_ids,
                  :item_admins_ids, :item_agents_attributes,
                  :access_condition_id,
                  :access_narrative, :private,
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

  opinio_subjectum

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
end
