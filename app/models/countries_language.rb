class CountriesLanguage < ActiveRecord::Base
  belongs_to :country
  belongs_to :language

  attr_accessible :language_id, :language, :country_id, :country

  validates :language_id, :presence => true
  #validates :country_id, :presence => true
end
