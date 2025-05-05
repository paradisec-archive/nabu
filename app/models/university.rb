# ## Schema Information
#
# Table name: `universities`
#
# ### Columns
#
# Name                    | Type               | Attributes
# ----------------------- | ------------------ | ---------------------------
# **`id`**                | `integer`          | `not null, primary key`
# **`name`**              | `string(255)`      |
# **`party_identifier`**  | `string(255)`      |
# **`created_at`**        | `datetime`         | `not null`
# **`updated_at`**        | `datetime`         | `not null`
#

class University < ApplicationRecord
  has_paper_trail

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :party_identifier, format: { with: URI::DEFAULT_PARSER.make_regexp, message: 'must be a valid URL' }, allow_nil: true

  normalizes :party_identifier, with: -> { _1.presence }

  has_many :collections, dependent: :restrict_with_exception
  has_many :items, dependent: :restrict_with_exception

  scope :alpha, -> { order(:name) }

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
    errors.add(:base, 'University used in items or collection - cannot be removed.') if items.count > 0 || collections.count > 0
    errors.empty?
  end

  def self.ransackable_attributes(_ = nil)
    %w[created_at id name party_identifier updated_at]
  end
end
