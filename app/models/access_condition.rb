class AccessCondition < ActiveRecord::Base
  scope :alpha, order(:name)

  attr_accessible :name

  validates :name, :presence => true
end
