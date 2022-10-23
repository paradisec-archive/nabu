# == Schema Information
#
# Table name: data_types
#
#  id   :integer          not null, primary key
#  name :string(255)      not null
#

class DataType < ActiveRecord::Base
  has_paper_trail

  validates :name, :presence => true, :uniqueness => true

  scope :alpha, -> { order(:name) }

  has_many :item_data_types
  has_many :items, :through => :item_data_types, :dependent => :restrict_with_exception
end
