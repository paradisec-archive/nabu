# ## Schema Information
#
# Table name: `fields_of_research`
#
# ### Columns
#
# Name              | Type               | Attributes
# ----------------- | ------------------ | ---------------------------
# **`id`**          | `integer`          | `not null, primary key`
# **`identifier`**  | `string(255)`      |
# **`name`**        | `string(255)`      |
#
# ### Indexes
#
# * `index_fields_of_research_on_identifier` (_unique_):
#     * **`identifier`**
# * `index_fields_of_research_on_name` (_unique_):
#     * **`name`**
#

class FieldOfResearch < ApplicationRecord
  has_paper_trail

  validates :name, :identifier, presence: true
  validates :name, :identifier, uniqueness: { case_sensitive: false }
  validates :identifier, numericality: { only_integer: true }

  scope :alpha, -> { order(:name) }

  def name_with_identifier
    "#{identifier} - #{name}"
  end

  has_many :collections, dependent: :restrict_with_exception

  def self.ransackable_attributes(_ = nil)
    %w[id identifier name]
  end
end
