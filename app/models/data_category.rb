# == Schema Information
#
# Table name: data_categories
#
#  id   :integer          not null, primary key
#  name :string(255)
#

class DataCategory < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true

  attr_accessible :name

  scope :alpha, order(:name)

  has_many :item_data_categories
  has_many :items, :through => :item_data_categories, :dependent => :restrict
end
