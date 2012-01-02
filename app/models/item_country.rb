class ItemCountry < ActiveRecord::Base
  belongs_to :country
  belongs_to :item

  attr_accessible :country_id, :country, :item_id, :item

  validates :country_id, :presence => true
  validates :item_id, :presence => true
end
