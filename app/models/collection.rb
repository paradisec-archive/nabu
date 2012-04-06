class Collection < ActiveRecord::Base
  belongs_to :collector, :class_name => "User"
  belongs_to :operator, :class_name => "User"
  belongs_to :university
  belongs_to :field_of_research
  belongs_to :access_condition

  has_many :items
  has_many :collection_languages, :dependent => :destroy
  has_many :languages, :through => :collection_languages, :validate => true

  has_many :collection_countries, :dependent => :destroy
  has_many :countries, :through => :collection_countries, :validate => true

  has_many :collection_admins, :dependent => :destroy
  has_many :admins, :through => :collection_admins, :validate => true, :source => :user

  validates :identifier, :presence => true, :uniqueness => true
  validates :title, :description, :presence => true
  validates :field_of_research_id, :presence => true
# FIXME: possibly re-activate these after import
#  validates :region, :presence => true
#  validates :university_id, :presence => true
#  validates :latitude, :longitude, :zoom, :presence => true
  validates :collector_id, :presence => true
  validates :latitude, :numericality => {:greater_than_or_equal_to => -90, :less_then_or_equal_to => 90}
  validates :longitude, :numericality => {:greater_than_or_equal_to => -180, :less_then_or_equal_to => 180}
  validates :zoom, :numericality => {:only_integer => true, :greater_than_or_equal_to => 0, :less_than => 22}

  attr_accessible :identifier, :title, :description, :region,
                  :latitude, :longitude, :zoom,
                  :collector_id, :operator_id, :university_id, :field_of_research_id,
                  :collection_languages_attributes, :collection_countries_attributes, :collection_admins_attributes,
                  :access_condition_id,
                  :access_narrative, :metadata_source, :orthographic_notes, :media, :comments,
                  :complete, :private, :tape_location, :deposit_form_recieved

  accepts_nested_attributes_for :collection_languages, :allow_destroy => true, :reject_if => :all_blank
  accepts_nested_attributes_for :collection_countries, :allow_destroy => true, :reject_if => :all_blank
  accepts_nested_attributes_for :collection_admins, :allow_destroy => true, :reject_if => :all_blank

  paginates_per 10

  before_create do |collection|
    collection.admins << collector
    if operator && collector.id != operator.id
      collection.admins << operator
    end
  end

  delegate :name, :to => :university, :prefix => true, :allow_nil => true
  delegate :name, :to => :collector, :prefix => true, :allow_nil => true
  delegate :name, :to => :operator, :prefix => true, :allow_nil => true
  delegate :name, :to => :access_condition, :prefix => true, :allow_nil => true

  searchable do
    integer :id
    string :identifier
    string :identifier
    text :identifier, :title, :description, :university_name
    text :collector_name
    text :operator_name
    integer :university_id, :references => University
    text :access_condition_name
    text :field_of_research do
      field_of_research.name
    end
    string :title
    string :region
    float :latitude
    float :longitude
    integer :zoom
    integer :language_ids, :references => Language, :multiple => true
    text :languages do
      languages.map(&:name)
    end
    integer :country_ids, :references => Country, :multiple => true
    text :countries do
      countries.map(&:name)
    end
    text :access_narrative
    text :metadata_source
    text :orthographic_notes
    text :media
    text :comments
    boolean :complete
    boolean :private
    text :tape_location
    boolean :deposit_form_recieved
  end
end
