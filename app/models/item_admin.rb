class ItemAdmin < ActiveRecord::Base
  belongs_to :user
  belongs_to :item

  attr_accessible :user_id, :item_id

  validates :user_id, :presence => true
  validates :item_id, :presence => true
end
