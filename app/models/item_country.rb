# == Schema Information
#
# Table name: item_countries
#
#  id         :integer          not null, primary key
#  item_id    :integer          not null
#  country_id :integer          not null
#

class ItemCountry < ActiveRecord::Base
  has_paper_trail

  belongs_to :country
  belongs_to :item

  attr_accessible :country_id, :country, :item_id, :item

  validates :country_id, :presence => true
  #validates :item_id, :presence => true
end
