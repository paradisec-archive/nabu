class DiscourseType < ActiveRecord::Base
  validates :name, :presence => true

  attr_accessible :name

  scope :alpha, order(:name)
end
