class CollectionCountry < ActiveRecord::Base
  belongs_to :country
  belongs_to :collection

  attr_accessible :country_id, :country, :collection_id, :collection

  validates :country_id, :presence => true
  validates :collection_id, :presence => true
end
