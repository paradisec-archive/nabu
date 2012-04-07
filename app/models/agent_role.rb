class AgentRole < ActiveRecord::Base
  scope :alpha, order(:name)
  attr_accessible :name

  validates :name, :presence => true, :uniqueness => true
end
