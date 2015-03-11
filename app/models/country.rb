class Country < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true

  attr_accessible :name, :code

  scope :alpha, order(:name)
  def name_with_code
    "#{name} - #{code}"
  end

  has_many :countries_languages
  has_many :languages, :through => :countries_languages, :dependent => :restrict

  has_many :item_languages
  has_many :items, :through => :item_languages, :dependent => :restrict

  has_many :collection_languages
  has_many :collections, :through => :collection_languages, :dependent => :restrict

  has_one :latlon_boundary
end
