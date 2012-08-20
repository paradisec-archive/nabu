class University < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true

  attr_accessible :name, :party_identifier

  scope :alpha, order(:name)
  paginates_per 10

  def full_path
    # FIX ME
    "http://catalog.paradisec.org.au/admin/universities/#{id}"
  end
end
