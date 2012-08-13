class FundingBody < ActiveRecord::Base
  attr_accessible :key_prefix, :name

  validates :name, :presence => true
  validates :name, :key_prefix, :uniqueness => true

  scope :alpha, order(:name)

  def name_with_identifier
    "#{name} #{key_prefix}"
  end

  has_many :collections, :dependent => :restrict
end
