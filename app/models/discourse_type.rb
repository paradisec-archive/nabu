# == Schema Information
#
# Table name: discourse_types
#
#  id   :integer          not null, primary key
#  name :string(255)      not null
#

class DiscourseType < ActiveRecord::Base
  validates :name, :presence => true

  attr_accessible :name

  scope :alpha, order(:name)

  has_many :items, :dependent => :restrict
end
