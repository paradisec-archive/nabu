# ## Schema Information
#
# Table name: `item_users`
#
# ### Columns
#
# Name           | Type               | Attributes
# -------------- | ------------------ | ---------------------------
# **`id`**       | `integer`          | `not null, primary key`
# **`item_id`**  | `integer`          | `not null`
# **`user_id`**  | `integer`          | `not null`
#
# ### Indexes
#
# * `index_item_users_on_item_id_and_user_id` (_unique_):
#     * **`item_id`**
#     * **`user_id`**
#

class ItemUser < ApplicationRecord
  has_paper_trail

  belongs_to :user
  belongs_to :item

  validates :user_id, presence: true
  # RAILS bug - can't save item_user without item having been saved
  #  validates :item_id, :presence => true
end
