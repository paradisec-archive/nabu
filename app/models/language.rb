class Language < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true

  attr_accessible :name, :code, :retired, :north_limit, :south_limit, :west_limit, :east_limit

  default_scope includes(:countries)
  scope :alpha, order(:name)
  def name_with_code
    "#{name} - #{code}"
  end

  has_many :countries_languages
  has_many :countries, :through => :countries_languages, :dependent => :restrict

  has_many :item_content_languages
  has_many :items_for_content, :through => :item_content_languages, :dependent => :restrict

  has_many :item_subject_languages
  has_many :items_for_subject, :through => :item_subject_languages, :dependent => :restrict

  has_many :collection_languages
  has_many :collections, :through => :collection_languages, :dependent => :restrict
end
