class AccessCondition < ActiveRecord::Base
  validates :name, :presence => true

  attr_accessible :name
end
