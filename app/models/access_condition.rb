class AccessCondition < ActiveRecord::Base
  scope :alpha, order(:name)

  attr_accessible :name

  validates :name, :presence => true

  has_many :items,       :dependent => :restrict
  has_many :collections, :dependent => :restrict
end
