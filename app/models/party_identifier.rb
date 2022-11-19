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
# **`created_at`**  | `datetime`         | `not null`
# **`updated_at`**  | `datetime`         | `not null`
# **`user_id`**     | `integer`          | `not null`
#
class PartyIdentifier < ApplicationRecord
  TYPES = [:NLA, :ORCID]

  belongs_to :user

  validates_presence_of :user_id, :party_type
  validates_uniqueness_of :party_type, scope: :user_id
end
