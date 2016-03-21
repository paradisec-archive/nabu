# == Schema Information
#
# Table name: admin_messages
#
#  id         :integer          not null, primary key
#  message    :text             default(""), not null
#  start_at   :datetime         not null
#  finish_at  :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AdminMessage < ActiveRecord::Base
  validates :message, presence: true
  validates :start_at, presence: true
  validates :finish_at, presence: true
  attr_accessible :finish_at, :message, :start_at
end
