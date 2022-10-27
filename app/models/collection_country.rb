# == Schema Information
#
# Table name: collection_countries
#
#  id            :integer          not null, primary key
#  collection_id :integer
#  country_id    :integer
#

class CollectionCountry < ApplicationRecord
  has_paper_trail

  belongs_to :country
  belongs_to :collection

  validates :country_id, :presence => true
  #validates :collection_id, :presence => true
end
