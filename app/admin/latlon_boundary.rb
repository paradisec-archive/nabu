ActiveAdmin.register LatlonBoundary, as: 'CountryBoundary' do
  menu :parent => 'Other Entities'
  actions :all, :except => [:destroy]

  permit_params :north_limit, :south_limit, :west_limit, :east_limit, :country, :country_id, :wrapped

  index do |boundaries|
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
