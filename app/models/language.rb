class Language < ActiveRecord::Base
  belongs_to :country

  validates :name, :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true
  validates :country, :presence => true, :associated => true

  attr_accessible :name, :code, :country_id

  scope :alpha, order(:name)
  def name_with_code
    "#{code} - #{name}"
  end
end
