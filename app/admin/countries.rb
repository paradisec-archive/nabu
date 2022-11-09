# ## Schema Information
#
# Table name: `countries`
#
# ### Columns
#
# Name        | Type               | Attributes
# ----------- | ------------------ | ---------------------------
# **`id`**    | `integer`          | `not null, primary key`
# **`code`**  | `string(255)`      |
# **`name`**  | `string(255)`      |
#
# ### Indexes
#
# * `index_countries_on_code` (_unique_):
#     * **`code`**
# * `index_countries_on_name` (_unique_):
#     * **`name`**
#
ActiveAdmin.register Country do
  menu :parent => "Other Entities"
  config.sort_order = "name_asc"
  actions :all, :except => [:destroy]

  permit_params :name, :code

  # Don't filter by countries_languages, languages, or latlon boundaries
  filter :code
  filter :name
end
