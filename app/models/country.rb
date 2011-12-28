class Country < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true

  attr_accessible :name, :code
end
