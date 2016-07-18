class ItemDataType < ActiveRecord::Base
  has_paper_trail

  belongs_to :data_type
  belongs_to :item

  attr_accessible :data_type_id, :data_type, :item_id, :item

  validates :data_type_id, :presence => true
  validates :item_id, :presence => true
end
