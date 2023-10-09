# ## Schema Information
#
# Table name: `access_conditions`
#
# ### Columns
#
# Name              | Type               | Attributes
# ----------------- | ------------------ | ---------------------------
# **`id`**          | `integer`          | `not null, primary key`
# **`name`**        | `string(255)`      |
# **`created_at`**  | `datetime`         | `not null`
# **`updated_at`**  | `datetime`         | `not null`
#
ActiveAdmin.register AccessCondition do
  menu parent: 'Other Entities'
  config.sort_order = 'name_asc'
  actions :all

  permit_params :name

  # Don't filter by items or collections
  filter :name
  filter :created_at
  filter :updated_at
end
