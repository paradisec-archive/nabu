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
ActiveAdmin.register PartyIdentifier do
  menu :parent => "Other Entities"
  config.sort_order = "identifier_asc"
  actions :all

  permit_params :user_id, :party_type, :identifier

  filter :user
  filter :party_type
  filter :identifier
end
