class ItemCountry < ActiveRecord::Base
  belongs_to :country
  belongs_to :item

  attr_accessible :country_id, :item_id

  validates :country_id, :presence => true
  validates :item_id, :presence => true
end
