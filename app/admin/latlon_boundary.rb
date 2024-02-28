# ## Schema Information
#
# Table name: `latlon_boundaries`
#
# ### Columns
#
# Name               | Type               | Attributes
# ------------------ | ------------------ | ---------------------------
# **`id`**           | `integer`          | `not null, primary key`
# **`east_limit`**   | `decimal(6, 3)`    | `not null`
# **`north_limit`**  | `decimal(6, 3)`    | `not null`
# **`south_limit`**  | `decimal(6, 3)`    | `not null`
# **`west_limit`**   | `decimal(6, 3)`    | `not null`
# **`wrapped`**      | `boolean`          | `default(FALSE)`
# **`country_id`**   | `integer`          | `not null`
#
# ### Indexes
#
# * `index_latlon_boundaries_on_country_id`:
#     * **`country_id`**

ActiveAdmin.register LatlonBoundary, as: 'CountryBoundary' do
  menu parent: 'Other Entities'

  includes :country

  actions :all, except: [:destroy]

  permit_params :north_limit, :south_limit, :west_limit, :east_limit, :country, :country_id, :wrapped

  config.filters = false

  index do
    column :id
    column :country do |boundary|
      link_to boundary.country.name, boundary.country
    end
    column :north_limit
    column :east_limit
    column :south_limit
    column :west_limit
    column :wrapped
    actions
  end
end
