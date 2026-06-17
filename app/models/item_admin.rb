# ## Schema Information
#
# Table name: `item_admins`
# Database name: `primary`
#
# ### Columns
#
# Name           | Type               | Attributes
# -------------- | ------------------ | ---------------------------
# **`id`**       | `integer`          | `not null, primary key`
# **`item_id`**  | `integer`          | `not null`
# **`user_id`**  | `bigint`           | `not null`
#
# ### Indexes
#
# * `index_item_admins_on_item_id_and_user_id` (_unique_):
#     * **`item_id`**
#     * **`user_id`**
# * `index_item_admins_on_user_id`:
#     * **`user_id`**
#
# ### Foreign Keys
#
# * `fk_rails_...` (_ON DELETE => cascade_):
#     * **`item_id => items.id`**
# * `fk_rails_...` (_ON DELETE => cascade_):
#     * **`user_id => users.id`**
#

class ItemAdmin < ApplicationRecord
  include RejectsContactGrants

  has_paper_trail

  belongs_to :user
  belongs_to :item

  validates :user_id, presence: true
  # RAILS bug - can't save item_admin without item having been saved
  #  validates :item_id, :presence => true

  after_commit :reindex_item_essences

  private

  def reindex_item_essences
    item.essences.reindex(mode: :async)
  end
end
