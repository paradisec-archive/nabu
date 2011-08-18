class University < ActiveRecord::Base
  attr_accessible :name

  #has_many :models, :dependent => :restrict


  validates :name, :presence => true
end
