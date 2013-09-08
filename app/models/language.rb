class Language < ActiveRecord::Base
  validates :name, :presence => true
  validates :code, :presence => true, :uniqueness => true

  attr_accessible :name, :code, :retired, :north_limit, :south_limit, :west_limit, :east_limit, :countries_languages_attributes

  default_scope includes(:countries)
  scope :alpha, order(:name)
  def name_with_code
    "#{name} - #{code}"
  end

  has_many :countries_languages
  has_many :countries, :through => :countries_languages, :dependent => :destroy
  accepts_nested_attributes_for :countries_languages, :allow_destroy => true
  #validates :countries, :length => { :minimum => 1 }

  has_many :item_content_languages
  has_many :items, :through => :item_content_languages, :dependent => :restrict

  has_many :item_subject_languages
  has_many :items, :through => :item_subject_languages, :dependent => :restrict

  has_many :collection_languages
  has_many :collections, :through => :collection_languages, :dependent => :restrict
end
