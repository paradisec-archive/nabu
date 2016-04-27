# == Schema Information
#
# Table name: languages
#
#  id          :integer          not null, primary key
#  code        :string(255)
#  name        :string(255)
#  retired     :boolean
#  north_limit :float
#  south_limit :float
#  west_limit  :float
#  east_limit  :float
#

class Language < ActiveRecord::Base
  has_paper_trail

  validates :name, :presence => true
  validates :code, :presence => true, :uniqueness => true

  attr_accessible :name, :code, :retired, :north_limit, :south_limit, :west_limit, :east_limit, :countries_languages_attributes

  default_scope includes(:countries)
  scope :alpha, order(:name)
  def name_with_code
    "#{name} - #{code}"
  end

  def language_archive_link
    "http://www.language-archives.org/language/#{code}"
  end

  has_many :countries_languages
  has_many :countries, :through => :countries_languages, :dependent => :destroy
  accepts_nested_attributes_for :countries_languages, :allow_destroy => true
  #validates :countries, :length => { :minimum => 1 }

  has_many :item_content_languages
  has_many :items_for_content, :through => :item_content_languages, :source => :item, :dependent => :restrict

  has_many :item_subject_languages
  has_many :items_for_subject, :through => :item_subject_languages, :source => :item, :dependent => :restrict

  has_many :collection_languages
  has_many :collections, :through => :collection_languages, :dependent => :restrict
end
