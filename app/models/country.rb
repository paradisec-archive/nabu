class Country < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true

  attr_accessible :name, :code

  def name_with_code
    "#{code} - #{name}"
  end
end
