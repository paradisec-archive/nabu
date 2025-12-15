# ## Schema Information
#
# Table name: `grants`
# Database name: `primary`
#
# ### Columns
#
# Name                    | Type               | Attributes
# ----------------------- | ------------------ | ---------------------------
# **`id`**                | `integer`          | `not null, primary key`
# **`grant_identifier`**  | `string(255)`      |
# **`collection_id`**     | `integer`          |
# **`funding_body_id`**   | `integer`          |
#
# ### Indexes
#
# * `index_grants_on_collection_id`:
#     * **`collection_id`**
# * `index_grants_on_collection_id_and_funding_body_id`:
#     * **`collection_id`**
#     * **`funding_body_id`**
# * `index_grants_on_funding_body_id`:
#     * **`funding_body_id`**
#

class Grant < ApplicationRecord
  has_paper_trail

  belongs_to :collection
  belongs_to :funding_body

  validates_uniqueness_of :grant_identifier, scope: [:collection_id, :funding_body_id], allow_blank: true, allow_nil: true

  scope :alpha, -> { order('funding_body.name') }
end
