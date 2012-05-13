class Language < ActiveRecord::Base
  belongs_to :country

  validates :name, :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true
  validates :country, :presence => true, :associated => true

  attr_accessible :name, :code, :country_id

  scope :alpha, order(:name)
  def name_with_code
    "#{code} - #{name}"
  end

  has_many :item_content_langages,
  has_many :items_for_content, :through => :item_content_langages, :dependent => :restrict

  has_many :item_subject_langages,
  has_many :items_for_subject, :through => :item_subject_langages, :dependent => :restrict

  has_many :collection_langages,
  has_many :collections, :through => :collection_langages, :dependent => :restrict
end
