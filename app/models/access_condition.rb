# == Schema Information
#
# Table name: access_conditions
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AccessCondition < ActiveRecord::Base
  scope :alpha, order(:name)

  attr_accessible :name

  validates :name, :presence => true

  has_many :items,       :dependent => :restrict
  has_many :collections, :dependent => :restrict
end
