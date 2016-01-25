ActiveAdmin.register Country do
  menu :parent => "Other Entities"
  config.sort_order = "name"
  actions :all, :except => [:destroy]

  # Don't filter by countries_languages, languages, collection_languages, collections, or latlon boundaries
  filter :code
  filter :name
end
