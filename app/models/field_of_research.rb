class FieldOfResearch < ActiveRecord::Base
  validates :name, :identifier, :presence => true
  validates :name, :identifier, :uniqueness => true
  validates :identifier, :numericality => {:only_integer => true}

  scope :alpha, order(:name)
  attr_accessible :name, :identifier

  def name_with_identifier
    "#{identifier} - #{name}"
  end

  has_many :collections, :dependent => :restrict
end
