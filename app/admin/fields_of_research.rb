ActiveAdmin.register FieldOfResearch do
  menu :parent => "Other Entities"
  config.sort_order = "name_asc"
  actions :all, :except => [:destroy]

  permit_params :name, :identifier

  # Don't filter by collections
  filter :identifier
  filter :name
end
