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
# **`user_id`**        | `bigint`           | `not null`
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
# ### Foreign Keys
#
# * `fk_rails_...` (_ON DELETE => cascade_):
#     * **`collection_id => collections.id`**
# * `fk_rails_...` (_ON DELETE => cascade_):
#     * **`user_id => users.id`**
#

class CollectionUser < ApplicationRecord
  include RejectsContactGrants

  has_paper_trail

  belongs_to :user
  belongs_to :collection

  validates :user_id, presence: true
  validates :collection_id, uniqueness: { scope: [:collection_id, :user_id] }

  after_commit :reindex_search_documents

  private

  # A collection user appears in the search index of the collection (user_ids),
  # its items (collection_user_ids) and its essences (collection_user_ids), so all
  # three must be reindexed when access is granted or revoked.
  def reindex_search_documents
    collection.reindex(mode: :async)
    collection.items.reindex(mode: :async)
    collection.essences.reindex(mode: :async)
  end
end
