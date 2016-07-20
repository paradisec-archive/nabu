# == Schema Information
#
# Table name: item_data_types
#
#  id           :integer          not null, primary key
#  item_id      :integer          not null
#  data_type_id :integer          not null
#

class ItemDataType < ActiveRecord::Base
  has_paper_trail

  belongs_to :data_type
  belongs_to :item

  attr_accessible :data_type_id, :data_type, :item_id, :item

  validates :data_type_id, :presence => true
  validates :item_id, :presence => true
end
