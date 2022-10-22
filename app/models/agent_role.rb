# == Schema Information
#
# Table name: agent_roles
#
#  id   :integer          not null, primary key
#  name :string(255)      not null
#

class AgentRole < ActiveRecord::Base
  has_paper_trail

  scope :alpha, -> { order(:name) }

  validates :name, :presence => true, :uniqueness => true

  has_many :item_agents, :dependent => :restrict

  def destroy
    ok_to_destroy? ? super : self
  end

  private

  def ok_to_destroy?
    errors.clear
    errors.add(:base, "Role used in items - cannot be removed.") if item_agents.count > 0
    errors.empty?
  end
end
