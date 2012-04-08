class Country < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true

  attr_accessible :name, :code

  scope :alpha, order(:name)

  def name_with_code
    "#{code} - #{name}"
  end
end
