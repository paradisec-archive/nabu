# == Schema Information
#
# Table name: item_users
#
#  id      :integer          not null, primary key
#  item_id :integer          not null
#  user_id :integer          not null
#

class ItemUser < ActiveRecord::Base
  has_paper_trail

  belongs_to :user
  belongs_to :item

  validates :user_id, :presence => true
# RAILS bug - can't save item_user without item having been saved
#  validates :item_id, :presence => true
end
