class LatlonBoundary < ActiveRecord::Base
  belongs_to :country

  attr_accessible :north_limit, :south_limit, :west_limit, :east_limit, :country, :wrapped
  validates_presence_of :north_limit, :south_limit, :west_limit, :east_limit, :country
end