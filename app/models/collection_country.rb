class CollectionCountry < ActiveRecord::Base
  belongs_to :country
  belongs_to :collection

  validates :country_id, :presence => true
end
