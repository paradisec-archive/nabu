ActiveAdmin.register User do
  sidebar :paginate, :only => :index  do
    para button_tag 'Show 10', :class => 'per_page', :data => {:per => 10}
    para button_tag 'Show 50', :class => 'per_page', :data => {:per => 50}
    button_tag "Show all #{User.count}", :class => 'per_page', :data => {:per => count}
  end

  # change pagination
  before_filter :only => :index do
    @per_page = params[:per_page] || 30
  end

  # index page search sidebar
  filter :user
  filter :essence

  # index page
  index do
    id_column
    column :user
    column :essence
    column :item
    column :collection
    column :created_at
    default_actions
  end

  # show page
  show do |user|
    attributes_table do
      row :id
      row :user
      row :essence
      row :item
      row :collection
      row :created_at
    end
  end
end
