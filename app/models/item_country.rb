class ItemCountry < ActiveRecord::Base
  belongs_to :country
  belongs_to :item
end
