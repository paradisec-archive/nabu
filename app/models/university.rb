class University < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true

  attr_accessible :name

  scope :alpha, order(:name)
  paginates_per 10
end
