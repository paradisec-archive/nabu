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
  # Sources own every field but the Bounding box, so rows are never created or deleted by hand.
  actions :index, :show, :edit, :update

  permit_params :north_limit, :south_limit, :west_limit, :east_limit

  filter :countries
  filter :code
  filter :source, as: :select, collection: -> { Language::SOURCE_NAMES.invert }
  filter :name
  filter :dialect
  filter :retired
  # Don't filter by items_for_content, items_for_subject, or collections.
  # Doesn't make sense.
  # Don't filter by north_limit, east_limit, south_limit or west_limit .
  # No strong business case for doing so.

  index do
    column :code
    column(:source) { |language| Language::SOURCE_NAMES[language.source] }
    column :name
    column :dialect
    column :retired
    column('Box') { |language| status_tag language.has_all_boundaries? }
    actions
  end

  # show page
  show do |language|
    attributes_table_for(resource)  do
      row :id
      row :code
      row(:source) { Language::SOURCE_NAMES[language.source] }
      row :name
      row :dialect
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
    f.inputs "Bounding box for #{f.object.label}" do
      f.input :north_limit
      f.input :east_limit
      f.input :south_limit
      f.input :west_limit
    end
    f.actions
  end
end
