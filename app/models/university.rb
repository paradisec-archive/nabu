class University < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true

  attr_accessible :name, :party_identifier

  has_many :collections, :dependent => :restrict
  has_many :items, :dependent => :restrict

  scope :alpha, order(:name)
  paginates_per 10

  def full_path
    # FIX ME
    "http://catalog.paradisec.org.au/admin/universities/#{id}"
  end

  def xml_key
    "paradisec.org.au/university/#{id}"
  end

  def destroy
    ok_to_destroy? ? super : self
  end

  private

  def ok_to_destroy?
    errors.clear
    errors.add(:base, "University used in items or collection - cannot be removed.") if items.count > 0 || collections.count > 0
    errors.empty?
  end
end
