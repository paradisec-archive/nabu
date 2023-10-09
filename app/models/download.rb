# ## Schema Information
#
# Table name: `downloads`
#
# ### Columns
#
# Name              | Type               | Attributes
# ----------------- | ------------------ | ---------------------------
# **`id`**          | `integer`          | `not null, primary key`
# **`created_at`**  | `datetime`         | `not null`
# **`updated_at`**  | `datetime`         | `not null`
# **`essence_id`**  | `integer`          |
# **`user_id`**     | `integer`          |
#
# ### Indexes
#
# * `index_downloads_on_essence_id`:
#     * **`essence_id`**
# * `index_downloads_on_user_id`:
#     * **`user_id`**
#

class Download < ApplicationRecord
  # As Download records aren't modified, no need for paper_trail

  belongs_to :user
  belongs_to :essence

  has_one :item, through: :essence

  delegate :collection, to: :item

  validates :user, associated: true
  validates :essence, associated: true

  def self.ransackable_attributes(_ = nil)
    %w[created_at essence_id id updated_at user_id]
  end

  def self.ransackable_associations(_ = nil)
    %w[essence item user]
  end
end
