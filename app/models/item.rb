class Item < ActiveRecord::Base
  belongs_to :collection
  belongs_to :collector, :class_name => 'User'
  belongs_to :operator, :class_name => 'User'
  belongs_to :university
  belongs_to :access_condition
  belongs_to :subject_language, :class_name => 'Language'
  belongs_to :content_language, :class_name => 'Language'
  belongs_to :discourse_type

  has_many :item_countries, :dependent => :destroy
  has_many :countries, :through => :item_countries, :validate => true

  has_many :item_admins, :dependent => :destroy
  has_many :admins, :through => :item_admins, :validate => true, :source => :user

  has_many :item_agents, :dependent => :destroy
  has_many :agents, :through => :item_agents, :validate => true, :source => :user

  validates :identifier, :presence => true, :uniqueness => true
  validates :title, :description, :region, :presence => true
  validates :collector_id, :university_id, :operator_id, :presence => true
  validates :latitude, :presence => true, :numericality => {:greater_than_or_equal_to => -90, :less_then_or_equal_to => 90}
  validates :longitude, :presence => true, :numericality => {:greater_than_or_equal_to => -180, :less_then_or_equal_to => 180}
  validates :zoom, :presence => true, :numericality => {:only_integer => true, :greater_than_or_equal_to => 0, :less_than => 22}
  validates :subject_language_id, :content_language_id, :discourse_type_id, :presence => true
  validates :originated_on, :presence => true

  attr_accessible :identifier, :title, :url, :description, :region,
                  :latitude, :longitude, :zoom,
                  :collector_id, :university_id, :operator_id,
                  :item_countries_attributes, :item_admins_attributes, :item_agents_attributes,
                  :access_condition_id,
                  :access_narrative, :private,
                  :originated_on, :language, :subject_language_id, :content_language_id,
                  :dialect, :discourse_type_id, :citation

  accepts_nested_attributes_for :item_countries, :allow_destroy => true, :reject_if => :all_blank
  accepts_nested_attributes_for :item_admins, :allow_destroy => true, :reject_if => :all_blank
  accepts_nested_attributes_for :item_agents, :allow_destroy => true, :reject_if => :all_blank

  paginates_per 10

  after_initialize :prefill

  def url
    'http://paradisec.org.au/repository/' + collection.identifier + '/' + identifier
  end

  def prefill
    return unless collection
    return unless new_record?
    self.university_id = collection.university_id
    self.collector_id = collection.collector_id
    self.region = collection.region
    self.latitude = collection.latitude
    self.longitude = collection.longitude
    self.zoom = collection.zoom
    collection.collection_countries.each do |collection_country|
      self.item_countries.build :country_id => collection_country.country_id
    end

    self.access_condition_id = collection.access_condition_id
    self.access_narrative = collection.access_narrative
    collection.collection_admins.each do |collection_admin|
      self.item_admins.build :user_id => collection_admin.user_id
    end

  end
end
