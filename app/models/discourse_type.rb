# == Schema Information
#
# Table name: discourse_types
#
#  id   :integer          not null, primary key
#  name :string(255)      not null
#

class DiscourseType < ApplicationRecord
  has_paper_trail

  validates :name, :presence => true

  scope :alpha, -> { order(:name) }

  has_many :items, :dependent => :restrict_with_exception
end
