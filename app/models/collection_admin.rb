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
# **`user_id`**        | `integer`          | `not null`
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

class CollectionAdmin < ApplicationRecord
  has_paper_trail

  belongs_to :user
  belongs_to :collection

  # RAILS bug - can't save collection_admin without collection_admin having been saved
  #  validates :collection_id, :presence => true
  validates :user_id, presence: true
  validates :collection_id, uniqueness: { scope: [:collection_id, :user_id] }
end
