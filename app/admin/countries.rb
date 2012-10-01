ActiveAdmin.register Country do
  menu :parent => "Other Entities"
  config.sort_order = "name"
  actions :all, :except => [:destroy]
end
