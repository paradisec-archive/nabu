# ## Schema Information
#
# Table name: `data_categories`
#
# ### Columns
#
# Name        | Type               | Attributes
# ----------- | ------------------ | ---------------------------
# **`id`**    | `integer`          | `not null, primary key`
# **`name`**  | `string(255)`      |
#
# ### Indexes
#
# * `index_data_categories_on_name` (_unique_):
#     * **`name`**
#

class DataCategory < ApplicationRecord
  has_paper_trail

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :alpha, -> { order(:name) }

  has_many :item_data_categories
  has_many :items, through: :item_data_categories, dependent: :restrict_with_exception

  def self.ransackable_attributes(_ = nil)
    %w[id name]
  end
end
