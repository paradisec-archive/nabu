ActiveAdmin.register Download do
  sidebar :paginate, :only => :index  do
    para button_tag 'Show 10', :class => 'per_page', :data => {:per => 10}
    para button_tag 'Show 50', :class => 'per_page', :data => {:per => 50}
    count = Download.count
    button_tag "Show all #{count}", :class => 'per_page', :data => {:per => count}
  end

  # change pagination
  before_filter :only => :index do
    @per_page = params[:per_page] || 30
  end

  # index page search sidebar
  filter :user_first_name, :as => :string
  filter :user_last_name, :as => :string
  filter :essence_item_identifier, :as => :string, :label => 'Item Identifier'
  filter :essence_item_collection_identifier, :as => :string, :label => 'Collection Identifier'
  filter :created_at

  # index page
  index do
    id_column
    column :user
    column :essence do |download|
      link_to download.essence.full_identifier, Rails.application.routes.url_helpers.collection_item_essence_path(download.collection, download.item, download.essence)
    end
    column :item do |download|
      link_to download.item.full_identifier, Rails.application.routes.url_helpers.collection_item_path(download.collection, download.item)
    end
    column :collection do |download|
      link_to download.collection.identifier, Rails.application.routes.url_helpers.collection_path(download.collection)
    end
    column :created_at
    default_actions
  end

  # show page
  show do |download|
    attributes_table do
      row :id
      row :user
      row :essence do
        link_to download.essence.full_identifier, Rails.application.routes.url_helpers.collection_item_essence_path(download.collection, download.item, download.essence)
      end
      row :item do
        link_to download.item.full_identifier, Rails.application.routes.url_helpers.collection_item_path(download.collection, download.item)
      end
      row :collection do
        link_to download.collection.identifier, Rails.application.routes.url_helpers.collection_path(download.collection)
      end
      row :created_at
    end
  end
end
