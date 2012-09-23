Nabu::Application.routes.draw do

  ActiveAdmin.routes(self)

  devise_for :users

  authenticated :user do
    root :to => 'page#dashboard'
  end
  root :to => 'page#about'
  root :to => 'page#glossary'

  match '/about' => 'page#about'
  match '/contact' => 'page#contact'
  match '/glossary' => 'page#glossary'

  resources :users
  resources :countries, :only => [:index, :show]
  resources :languages, :only => [:index, :show]
  resources :data_categories, :only => [:index, :show]
  resources :collections do
    collection do
      get 'search' => 'collections#search'
      get 'advanced_search' => 'collections#advanced_search'
      get 'bulk_update' => 'collections#bulk_edit'
      put 'bulk_update' => 'collections#bulk_update'
    end
    resources :items do
      resources :essences, :only => [:show, :download] do
        member do
          get :download
          get :display
        end
      end
    end
  end
  resources :items, :only => [] do
    collection do
      get 'search' => 'items#search'
      get 'advanced_search' => 'items#advanced_search'
      get 'bulk_update' => 'items#bulk_edit'
      put 'bulk_update' => 'items#bulk_update'
    end
  end

  match '/repository/:collection_identifier' => 'repository#collection', :as => 'repository_collection'
  match '/repository/:collection_identifier/:item_identifier' => 'repository#item', :as => 'repository_item'
  match '/repository/:collection_identifier/:item_identifier/:essence_identifier' => 'repository#essence', :as => 'repository_essence'

  resources :comments, :shallow => true do
    match 'approve' => 'comments#approve', :on => :member, :via => :post
    match 'spam'    => 'comments#spam',    :on => :member, :via => :post
  end
  resources :universities, :only => :create

  scope '/oai' do
    match 'item' => 'oai#item'
    match 'collection' => 'oai#collection'
  end
end
