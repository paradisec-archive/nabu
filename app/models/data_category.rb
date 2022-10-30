# == Schema Information
#
# Table name: data_categories
#
#  id   :integer          not null, primary key
#  name :string(255)
#

class DataCategory < ApplicationRecord
  has_paper_trail

  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }

  scope :alpha, -> { order(:name) }

  has_many :item_data_categories
  has_many :items, :through => :item_data_categories, :dependent => :restrict_with_exception
end
