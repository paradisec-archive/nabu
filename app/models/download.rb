# == Schema Information
#
# Table name: downloads
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  essence_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Download < ActiveRecord::Base
  belongs_to :user
  belongs_to :essence

  has_one :item, :through => :essence

  delegate :collection, :to => :item

  attr_accessible :user, :essence

  validates :user, :associated => true
  validates :essence, :associated => true
end
