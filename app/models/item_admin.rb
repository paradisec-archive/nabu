class ItemAdmin < ActiveRecord::Base
  belongs_to :user
  belongs_to :item

  attr_accessible :user_id, :user, :item_id, :item

  validates :user_id, :presence => true
# RAILS bug - can't save item_admin without item having been saved
#  validates :item_id, :presence => true
end
