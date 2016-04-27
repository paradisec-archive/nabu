# == Schema Information
#
# Table name: funding_bodies
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  key_prefix :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class FundingBody < ActiveRecord::Base
  has_paper_trail

  attr_accessible :key_prefix, :name

  validates :name, :presence => true
  validates :name, :key_prefix, :uniqueness => true

  scope :alpha, order(:name)

  def name_with_identifier
    "#{name} #{key_prefix}"
  end

  has_many :grants
  has_many :collections, through: :grants, dependent: :restrict

  def destroy
    ok_to_destroy? ? super : self
  end

  private

  def ok_to_destroy?
    errors.clear
    errors.add(:base, "Funding body used in collections and cannot be removed.") if collections.count > 0
    errors.empty?
  end
end
