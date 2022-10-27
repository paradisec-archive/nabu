# == Schema Information
#
# Table name: countries
#
#  id   :integer          not null, primary key
#  code :string(255)
#  name :string(255)
#

class Country < ApplicationRecord
  has_paper_trail

  validates :name, :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true

  scope :alpha, -> { order(:name) }

  def name_with_code
    "#{name} - #{code}"
  end

  has_many :countries_languages
  has_many :languages, :through => :countries_languages, :dependent => :restrict_with_exception

  has_one :latlon_boundary


  def language_archive_link
    "http://www.language-archives.org/country/#{code.upcase}"
  end
end
