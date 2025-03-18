# ## Schema Information
#
# Table name: `data_categories`
#
# ### Columns
#
# Name        | Type               | Attributes
# ----------- | ------------------ | ---------------------------
# **`id`**    | `integer`          | `not null, primary key`
# **`name`**  | `string(255)`      |
#
# ### Indexes
#
# * `index_data_categories_on_name` (_unique_):
#     * **`name`**
#
ActiveAdmin.register DataCategory do
  menu parent: 'Other Entities'
  config.sort_order = 'name_asc'
  actions :all

  permit_params :name

  filter :name
  filter :created_at
  filter :updated_at
end
