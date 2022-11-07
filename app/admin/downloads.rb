ActiveAdmin.register Download do
  sidebar :paginate, :only => :index  do
    ['10', '50', "all #{Download.count}"].each do |n|
      para link_to "Show #{n}", params.permit!.merge(per_page: n.sub('all ', ''), page: n.start_with?('all') ? 1 : params[:page]), class: 'button'
    end
  end

  permit_params :user, :essence

  # change pagination
  before_action :only => :index do
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
      if download && download.essence
        link_to download.essence.full_identifier, Rails.application.routes.url_helpers.collection_item_essence_path(download.collection, download.item, download.essence)
      else
        "Essence #{download.essence_id}, now removed"
      end
    end
    column :item do |download|
      if download && download.essence
        link_to download.item.full_identifier, Rails.application.routes.url_helpers.collection_item_path(download.collection, download.item)
      end
    end
    column :collection do |download|
      if download && download.essence
        link_to download.collection.identifier, Rails.application.routes.url_helpers.collection_path(download.collection)
      end
    end
    column :created_at
    actions
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
