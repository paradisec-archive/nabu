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

    table_for language.countries do
      column "Countries" do |countries_languages|
        countries_languages.name
      end
    end

    div :class => 'map',
      :'data-north_limit' => language.north_limit,
      :'data-east_limit'  => language.east_limit,
      :'data-south_limit' => language.south_limit,
      :'data-west_limit'  => language.west_limit
  end

  form do |f|
    f.inputs "Language Details" do # physician's fields
      f.input :code
      f.input :name
      f.input :retired
      f.input :north_limit
      f.input :east_limit
      f.input :south_limit
      f.input :west_limit
    end

    f.has_many :countries_languages do |country|
      if !country.object.nil?
        country.input :_destroy, :as => :boolean, :label => "Destroy?"
      end
      country.input :country
    end
    f.actions
  end
end
