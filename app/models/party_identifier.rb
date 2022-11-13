# ## Schema Information
#
# Table name: `party_identifiers`
#
# ### Columns
#
# Name              | Type               | Attributes
# ----------------- | ------------------ | ---------------------------
# **`id`**          | `integer`          | `not null, primary key`
# **`identifier`**  | `string(255)`      | `not null`
# **`party_type`**  | `integer`          | `not null`
# **`created_at`**  | `datetime`         |
# **`updated_at`**  | `datetime`         |
# **`user_id`**     | `integer`          | `not null`
#
# ### Indexes
#
# * `index_party_identifiers_on_party_type`:
#     * **`party_type`**
# * `index_party_identifiers_on_user_id`:
#     * **`user_id`**
#
class PartyIdentifier < ApplicationRecord
  TYPES = [:NLA, :ORCID]

  belongs_to :user

  validates_presence_of :user_id, :party_type
  validates_uniqueness_of :party_type, scope: :user_id
end
