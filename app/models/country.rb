# == Schema Information
#
# Table name: countries
#
#  id   :integer          not null, primary key
#  code :string(255)
#  name :string(255)
#

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

  has_one :latlon_boundary
end
