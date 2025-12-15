# ## Schema Information
#
# Table name: `data_types`
# Database name: `primary`
#
# ### Columns
#
# Name        | Type               | Attributes
# ----------- | ------------------ | ---------------------------
# **`id`**    | `integer`          | `not null, primary key`
# **`name`**  | `string(255)`      | `not null`
#

class DataType < ApplicationRecord
  has_paper_trail

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :alpha, -> { order(:name) }

  has_many :item_data_types
  has_many :items, through: :item_data_types, dependent: :restrict_with_exception

  def self.ransackable_attributes(_ = nil)
    %w[id name]
  end
end
