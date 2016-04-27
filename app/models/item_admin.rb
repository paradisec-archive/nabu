# == Schema Information
#
# Table name: item_admins
#
#  id      :integer          not null, primary key
#  item_id :integer          not null
#  user_id :integer          not null
#

class ItemAdmin < ActiveRecord::Base
  has_paper_trail

  belongs_to :user
  belongs_to :item

  attr_accessible :user_id, :user, :item_id, :item

  validates :user_id, :presence => true
# RAILS bug - can't save item_admin without item having been saved
#  validates :item_id, :presence => true
end
