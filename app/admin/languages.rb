# ## Schema Information
#
# Table name: `languages`
# Database name: `primary`
#
# ### Columns
#
# Name               | Type               | Attributes
# ------------------ | ------------------ | ---------------------------
# **`id`**           | `integer`          | `not null, primary key`
# **`code`**         | `string(255)`      |
# **`dialect`**      | `boolean`          | `default(FALSE), not null`
# **`east_limit`**   | `float(24)`        |
# **`name`**         | `string(255)`      |
# **`north_limit`**  | `float(24)`        |
# **`retired`**      | `boolean`          | `default(FALSE), not null`
# **`source`**       | `string(255)`      | `not null`
# **`south_limit`**  | `float(24)`        |
# **`west_limit`**   | `float(24)`        |
#
# ### Indexes
#
# * `index_languages_on_code_and_source` (_unique_):
#     * **`code`**
#     * **`source`**
#
ActiveAdmin.register Language do
  menu parent: 'Other Entities'
  config.sort_order = 'name_asc'
  actions :all, except: [:destroy]

  permit_params :name, :code, :source, :retired, :north_limit, :south_limit, :west_limit, :east_limit, countries_languages_attributes: %i[_destroy country_id]

  filter :countries
  filter :code
  filter :name
  filter :retired
  # Don't filter by items_for_content, items_for_subject, or collections.
  # Doesn't make sense.
  # Don't filter by north_limit, east_limit, south_limit or west_limit .
  # No strong business case for doing so.

  # show page
  show do |language|
    attributes_table_for(resource)  do
      row :id
      row :code
      row :name
      row :retired
      row :north_limit
      row :east_limit
      row :south_limit
      row :west_limit
    end

    table_for language.countries do
      column 'Countries' do |countries_languages|
        countries_languages.name
      end
    end

    div class: 'map',
      'data-north_limit': language.north_limit,
      'data-east_limit': language.east_limit,
      'data-south_limit': language.south_limit,
      'data-west_limit': language.west_limit
  end

  form do |f|
    f.inputs 'Language Details' do # physician's fields
      f.input :code
      f.input :source
      f.input :name
      f.input :retired
      f.input :north_limit
      f.input :east_limit
      f.input :south_limit
      f.input :west_limit
    end

    f.has_many :countries_languages do |country|
      if !country.object.nil?
        country.input :_destroy, as: :boolean, label: 'Destroy?'
      end
      country.input :country
    end
    f.actions
  end
end
