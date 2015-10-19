# == Schema Information
#
# Table name: countries_languages
#
#  id          :integer          not null, primary key
#  country_id  :integer          not null
#  language_id :integer          not null
#

class CountriesLanguage < ActiveRecord::Base
  belongs_to :country
  belongs_to :language

  attr_accessible :language_id, :language, :country_id, :country

  validates :country_id, :presence => true
  #validates :language_id, :presence => true
end
