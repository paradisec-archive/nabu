# ## Schema Information
#
# Table name: `permissions`
# Database name: `primary`
#
# ### Columns
#
# Name                  | Type               | Attributes
# --------------------- | ------------------ | ---------------------------
# **`id`**              | `integer`          | `not null, primary key`
# **`grantable_type`**  | `string(255)`      | `not null`
# **`level`**           | `string(255)`      | `not null`
# **`created_at`**      | `datetime`         | `not null`
# **`updated_at`**      | `datetime`         | `not null`
# **`grantable_id`**    | `integer`          | `not null`
# **`user_id`**         | `bigint`           | `not null`
#
# ### Indexes
#
# * `index_permissions_on_grantable_and_user_and_level` (_unique_):
#     * **`grantable_type`**
#     * **`grantable_id`**
#     * **`user_id`**
#     * **`level`**
# * `index_permissions_on_user_id`:
#     * **`user_id`**
#
# ### Foreign Keys
#
# * `fk_rails_...` (_ON DELETE => cascade_):
#     * **`user_id => users.id`**
#
class Permission < ApplicationRecord
  include RejectsContactGrants

  has_paper_trail

  # grantable is polymorphic over Collection and Item; level maps the four old membership
  # tables onto one shape: collection_admins/item_admins -> edit, collection_users/item_users -> read.
  belongs_to :user
  belongs_to :grantable, polymorphic: true

  enum :level, { read: 'read', edit: 'edit' }

  validates :level, presence: true
  validates :user_id, uniqueness: { scope: %i[grantable_type grantable_id level] }

  after_commit :reindex_search_documents

  private

  # A grant is denormalised into the search index of its subject, the records that cascade
  # from it, and their essences, so all three must be reindexed when access changes. Mirrors
  # the scope of the four old membership models: a collection grant reindexes the collection,
  # its items and its essences; an item grant reindexes the item, its collection and its essences.
  def reindex_search_documents
    case grantable
    when Collection
      grantable.reindex(mode: :async)
      grantable.items.reindex(mode: :async)
      grantable.essences.reindex(mode: :async)
    when Item
      grantable.reindex(mode: :async)
      grantable.collection.reindex(mode: :async)
      grantable.essences.reindex(mode: :async)
    end
  end
end
