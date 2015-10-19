# == Schema Information
#
# Table name: item_data_categories
#
#  id               :integer          not null, primary key
#  item_id          :integer          not null
#  data_category_id :integer          not null
#

class ItemDataCategory < ActiveRecord::Base
  belongs_to :data_category
  belongs_to :item

  attr_accessible :data_category_id, :data_category, :item_id, :item

  validates :data_category_id, :presence => true
  #validates :item_id, :presence => true
end
