# == Schema Information
#
# Table name: item_agents
#
#  id            :integer          not null, primary key
#  item_id       :integer          not null
#  user_id       :integer          not null
#  agent_role_id :integer          not null
#

class ItemAgent < ActiveRecord::Base
  has_paper_trail

  belongs_to :user
  belongs_to :agent_role
  belongs_to :item

  attr_accessible :user_id, :user, :agent_role_id, :agent_role, :item_id, :item

  validates :user_id, :presence => true
  validates :agent_role_id, :presence => true
  validates_uniqueness_of :item_id, :scope => [:agent_role_id, :user_id]
end
