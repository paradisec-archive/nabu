# == Schema Information
#
# Table name: latlon_boundaries
#
#  id          :integer          not null, primary key
#  country_id  :integer          not null
#  east_limit  :decimal(6, 3)    not null
#  west_limit  :decimal(6, 3)    not null
#  north_limit :decimal(6, 3)    not null
#  south_limit :decimal(6, 3)    not null
#  wrapped     :boolean          default(FALSE)
#

class LatlonBoundary < ActiveRecord::Base
  has_paper_trail

  belongs_to :country

  attr_accessible :north_limit, :south_limit, :west_limit, :east_limit, :country, :country_id, :wrapped
  validates_presence_of :north_limit, :south_limit, :west_limit, :east_limit, :country
end