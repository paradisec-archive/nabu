# ## Schema Information
#
# Table name: `discourse_types`
# Database name: `primary`
#
# ### Columns
#
# Name        | Type               | Attributes
# ----------- | ------------------ | ---------------------------
# **`id`**    | `integer`          | `not null, primary key`
# **`name`**  | `string(255)`      | `not null`
#
# ### Indexes
#
# * `index_discourse_types_on_name` (_unique_):
#     * **`name`**
#

class DiscourseType < ApplicationRecord
  has_paper_trail

  validates :name, presence: true

  scope :alpha, -> { order(:name) }

  has_many :items, dependent: :restrict_with_exception
end
