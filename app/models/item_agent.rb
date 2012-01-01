class ItemAgent < ActiveRecord::Base
  belongs_to :user
  belongs_to :agent_role
  belongs_to :item

  attr_accessible :user_id, :agent_role_id, :item_id

  validates :user_id, :presence => true
  validates :agent_role_id, :presence => true
  validates :item_id, :presence => true
end
