class ItemDataCategory < ActiveRecord::Base
  belongs_to :data_category
  belongs_to :item

  attr_accessible :data_category_id, :data_category, :item_id, :item

  validates :data_category_id, :presence => true
  #validates :item_id, :presence => true
end
