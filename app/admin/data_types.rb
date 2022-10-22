ActiveAdmin.register DataType do
  menu :parent => "Other Entities"
  config.sort_order = "name_asc"
  actions :all

  permit_params :name

  filter :name
  filter :created_at
  filter :updated_at
end
