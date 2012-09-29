ActiveAdmin.register Language do
  menu :parent => "Other Entities"
  config.sort_order = "name"
  actions :all, :except => [:destroy]

  # show page
  show do |language|
    attributes_table  do
      row :id
      row :code
      row :name
      row :retired
      row :north_limit
      row :east_limit
      row :south_limit
      row :west_limit
    end

    div :class => 'map',
      :'data-north_limit' => language.north_limit,
      :'data-east_limit'  => language.east_limit,
      :'data-south_limit' => language.south_limit,
      :'data-west_limit'  => language.west_limit
  end

end
