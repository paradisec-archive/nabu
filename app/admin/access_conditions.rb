ActiveAdmin.register AccessCondition do
  menu :parent => "Other Entities"
  config.sort_order = "name_asc"
  actions :all

  # Don't filter by items or collections
  filter :name
  filter :created_at
  filter :updated_at
end
