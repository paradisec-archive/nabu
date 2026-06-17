# ## Schema Information
#
# Table name: `collection_users`
# Database name: `primary`
#
# ### Columns
#
# Name                 | Type               | Attributes
# -------------------- | ------------------ | ---------------------------
# **`id`**             | `integer`          | `not null, primary key`
# **`collection_id`**  | `integer`          | `not null`
# **`user_id`**        | `integer`          | `not null`
#
# ### Indexes
#
# * `index_collection_users_on_collection_id`:
#     * **`collection_id`**
# * `index_collection_users_on_collection_id_and_user_id` (_unique_):
#     * **`collection_id`**
#     * **`user_id`**
# * `index_collection_users_on_user_id`:
#     * **`user_id`**
#

class CollectionUser < ApplicationRecord
  has_paper_trail

  belongs_to :user
  belongs_to :collection

  validates :user_id, presence: true
  validates :collection_id, uniqueness: { scope: [:collection_id, :user_id] }

  after_commit :reindex_collection_essences

  private

  def reindex_collection_essences
    collection.essences.reindex(mode: :async)
  end
end
