class Collection < ActiveRecord::Base
  belongs_to :collector
  belongs_to :university
  belongs_to :field_of_research

  has_many :collection_languages, :dependent => :destroy
  has_many :languages, :through => :collection_languages, :validate => true

  has_many :collection_countries, :dependent => :destroy
  has_many :countries, :through => :collection_countries, :validate => true

  validates :identifier, :presence => true, :uniqueness => true
  validates :title, :description, :region, :presence => true
  validates :collector_id, :university_id, :field_of_research_id, :presence => true
  validates :latitude, :presence => true, :numericality => {:greater_than_or_equal_to => -90, :less_then_or_equal_to => 90}
  validates :longitude, :presence => true, :numericality => {:greater_than_or_equal_to => -180, :less_then_or_equal_to => 180}
  validates :zoom, :presence => true, :numericality => {:only_integer => true, :greater_than_or_equal_to => 0, :less_than => 22}

  attr_accessible :identifier, :title, :description, :region,
                  :latitude, :longitude, :zoom,
                  :collector_id, :university_id, :field_of_research_id,
                  :collection_languages_attributes, :collection_countries_attributes

  accepts_nested_attributes_for :collection_languages, :allow_destroy => true
  accepts_nested_attributes_for :collection_countries, :allow_destroy => true

end
