class AccessCondition < ActiveRecord::Base
  validates :name, :presence => true
end
