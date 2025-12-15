# ## Schema Information
#
# Table name: `funding_bodies`
# Database name: `primary`
#
# ### Columns
#
# Name              | Type               | Attributes
# ----------------- | ------------------ | ---------------------------
# **`id`**          | `integer`          | `not null, primary key`
# **`key_prefix`**  | `string(255)`      |
# **`name`**        | `string(255)`      | `not null`
# **`created_at`**  | `datetime`         | `not null`
# **`updated_at`**  | `datetime`         | `not null`
#

class FundingBody < ApplicationRecord
  has_paper_trail

  validates :name, presence: true
  validates :name, :key_prefix, uniqueness: true

  scope :alpha, -> { order(:name) }

  def name_with_identifier
    "#{name} #{key_prefix}"
  end

  has_many :grants
  has_many :collections, through: :grants, dependent: :restrict_with_exception

  def destroy
    ok_to_destroy? ? super : self
  end

  private

  def ok_to_destroy?
    errors.clear
    errors.add(:base, 'Funding body used in collections and cannot be removed.') if collections.positive?
    errors.empty?
  end

  def self.ransackable_attributes(_ = nil)
    %w[created_at id key_prefix name updated_at]
  end
end
