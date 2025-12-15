# ## Schema Information
#
# Table name: `fields_of_research`
# Database name: `primary`
#
# ### Columns
#
# Name              | Type               | Attributes
# ----------------- | ------------------ | ---------------------------
# **`id`**          | `integer`          | `not null, primary key`
# **`identifier`**  | `string(255)`      |
# **`name`**        | `string(255)`      |
#
# ### Indexes
#
# * `index_fields_of_research_on_identifier` (_unique_):
#     * **`identifier`**
# * `index_fields_of_research_on_name` (_unique_):
#     * **`name`**
#
ActiveAdmin.register FieldOfResearch do
  menu parent: 'Other Entities'
  config.sort_order = 'name_asc'
  actions :all, except: [:destroy]

  permit_params :name, :identifier

  # Don't filter by collections
  filter :identifier
  filter :name
end
