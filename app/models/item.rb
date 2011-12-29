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
                  :item_countries_attributes, :item_admins_attributes, :item_agents_attributes,
                  :access_condition_id,
                  :access_narrative, :private,
                  :originated_on, :language, :subject_language_id, :content_language_id,
                  :dialect, :discourse_type_id

  accepts_nested_attributes_for :item_countries, :allow_destroy => true, :reject_if => :all_blank
  accepts_nested_attributes_for :item_admins, :allow_destroy => true, :reject_if => :all_blank
  accepts_nested_attributes_for :item_agents, :allow_destroy => true, :reject_if => :all_blank

  paginates_per 10

  after_initialize :prefill

  def full_identifier
    collection.identifier + '-' + identifier
  end

  def citation
    cite = "#{collector.name} (recorder)"
    cite += ", #{operator.name} (depositor)" if operator
    cite += " #{originated_on.year}" if originated_on
    cite += '; '
    cite += title
    cite += " #{url}" if url
    cite += " #{Date.today}."
    cite
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

    self.access_condition_id ||= collection.access_condition_id
    self.access_narrative ||= collection.access_narrative
    if self.item_admins.empty?
      collection.collection_admins.each do |collection_admin|
        self.item_admins.build :user_id => collection_admin.user_id
      end
    end
  end
end
