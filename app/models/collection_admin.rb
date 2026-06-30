# ## Schema Information
#
# Table name: `collection_admins`
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
# * `index_collection_admins_on_collection_id`:
#     * **`collection_id`**
# * `index_collection_admins_on_collection_id_and_user_id` (_unique_):
#     * **`collection_id`**
#     * **`user_id`**
# * `index_collection_admins_on_user_id`:
#     * **`user_id`**
#
# ### Foreign Keys
#
# * `fk_rails_...` (_ON DELETE => cascade_):
#     * **`collection_id => collections.id`**
# * `fk_rails_...` (_ON DELETE => cascade_):
#     * **`user_id => users.id`**
#

class CollectionAdmin < ApplicationRecord
  include RejectsContactGrants

  has_paper_trail

  belongs_to :user
  belongs_to :collection

  # RAILS bug - can't save collection_admin without collection_admin having been saved
  #  validates :collection_id, :presence => true
  validates :user_id, presence: true
  validates :collection_id, uniqueness: { scope: [:collection_id, :user_id] }

  after_commit :reindex_search_documents

  private

  # A collection admin is denormalised onto the collection (admin_ids), every item in it
  # (collection_admin_ids) and its essences (collection_admin_ids), so all three indexes
  # must be reindexed when access is granted or revoked.
  def reindex_search_documents
    collection.reindex(mode: :async)
    collection.items.reindex(mode: :async)
    collection.essences.reindex(mode: :async)
  end
end
