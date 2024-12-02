# ## Schema Information
#
# Table name: `data_types`
#
# ### Columns
#
# Name        | Type               | Attributes
# ----------- | ------------------ | ---------------------------
# **`id`**    | `integer`          | `not null, primary key`
# **`name`**  | `string(255)`      | `not null`
#
ActiveAdmin.register DataType do
  menu parent: 'Other Entities'
  config.sort_order = 'name_asc'
  actions :all

  permit_params :name

  filter :name
  filter :created_at
  filter :updated_at
end
