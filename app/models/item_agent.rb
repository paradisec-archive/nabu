class ItemAgent < ActiveRecord::Base
  belongs_to :user
  belongs_to :agent_role
  belongs_to :item

  attr_accessible :user_id, :user, :agent_role_id, :agent_role, :item_id, :item

  validates :user_id, :presence => true
  validates :agent_role_id, :presence => true
  validates_uniqueness_of :item_id, :scope => [:agent_role_id, :user_id]
end
