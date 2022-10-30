# == Schema Information
#
# Table name: fields_of_research
#
#  id         :integer          not null, primary key
#  identifier :string(255)
#  name       :string(255)
#

class FieldOfResearch < ApplicationRecord
  has_paper_trail

  validates :name, :identifier, :presence => true
  validates :name, :identifier, :uniqueness => { case_sensitive: false }
  validates :identifier, :numericality => {:only_integer => true}

  scope :alpha, -> { order(:name) }

  def name_with_identifier
    "#{identifier} - #{name}"
  end

  has_many :collections, :dependent => :restrict_with_exception
end
