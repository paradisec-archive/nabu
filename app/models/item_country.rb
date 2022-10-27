# == Schema Information
#
# Table name: item_countries
#
#  id         :integer          not null, primary key
#  item_id    :integer          not null
#  country_id :integer          not null
#

class ItemCountry < ApplicationRecord
  has_paper_trail

  belongs_to :country
  belongs_to :item

  validates :country_id, :presence => true
  #validates :item_id, :presence => true
end
