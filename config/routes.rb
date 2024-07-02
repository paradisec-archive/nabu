# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  use_doorkeeper

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get '/up' => 'rails/health#show', as: :rails_health_check

  # Graphql
  get '/paradisec.graphql', to: 'graphql#schema', as: 'graphql_schema'
  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/graphql'
  post '/graphql', to: 'graphql#execute'

  # Admin
  ActiveAdmin.routes(self)

  # Auth
  devise_for :users, controllers: { registrations: 'registrations' }

  root to: 'page#home'

  get '/contact' => 'page#contact'
  get '/dashboard' => 'page#dashboard'
  get '/glossary' => 'page#glossary'
  get '/apidoc' => 'page#apidoc'
  get '/tlcmap' => 'page#tlcmap'

  post 'versions/:id/revert' => 'versions#revert', :as => 'revert_version'

  get '/users' => 'users#index'
  get '/users/:id' => 'users#show'

  resources :countries, only: %i[index show]
  resources :languages, only: %i[index show]
  resources :data_categories, only: %i[index show]
  resources :data_types, only: %i[index show]
  resources :collections do
    collection do
      get 'last_search' => 'collections#return_to_last_search'
      get 'search' => 'collections#search'
      get 'advanced_search' => 'collections#advanced_search'
      get 'bulk_update' => 'collections#bulk_edit'
      patch 'bulk_update' => 'collections#bulk_update'
      get 'metadata' => 'collections#new_from_metadata'
      post 'exsite9' => 'collections#create_from_exsite9'
      post 'spreadsheet' => 'collections#create_from_spreadsheet'
    end
    resources :items, except: %i[index] do
      member do
        get :s3_rocrate
        get :private_rocrate
        get :public_rocrate
        get :data
        patch :inherit_details
      end
      resources :essences, only: %i[show download destroy] do
        member do
          get :download
          get :display
          get :show_terms
          get :agree_to_terms
        end
      end
    end
  end
  resources :items, only: [] do
    collection do
      get 'last_search' => 'items#return_to_last_search'
      get 'search' => 'items#search'
      get 'advanced_search' => 'items#advanced_search'
      get 'bulk_update' => 'items#bulk_edit'
      patch 'bulk_update' => 'items#bulk_update'
      get 'new_report' => 'items#new_report'
      post 'send_report' => 'items#send_report'
      get 'report_sent' => 'items#report_sent'
    end
  end

  resources :collections do
    resources :items, only: %i[] do
      member do
        get 'ro-crate-metadata.json', to: 'items#show', as: 'rocrate', defaults: { format: :rocrate }
      end
    end
  end

  get '/repository/:collection_identifier' => 'repository#collection', :as => 'repository_collection'
  get '/repository/:collection_identifier/:item_identifier' => 'repository#item', :as => 'repository_item'
  get '/repository/:collection_identifier/:item_identifier/:essence_filename' => 'repository#essence',
      :as => 'repository_essence',
      :constraints => { essence_filename: /.*/ }

  get '/items/*full_identifier' => 'repository#item', :as => 'repository_collection_item'

  get '/essences/mimetypes' => 'essences#list_mimetypes', as: 'list_mimetypes'

  resources :comments, shallow: true do
    post 'approve' => 'comments#approve', :on => :member
    post 'spam'    => 'comments#spam',    :on => :member
  end
  resources :universities, only: :create

  scope '/oai', as: 'oai' do
    get 'item' => 'oai#item'
    post 'item' => 'oai#item'
    get 'collection' => 'oai#collection'
    post 'collection' => 'oai#collection'
  end

  authenticated :user, ->(user) { user.admin? } do
    mount Delayed::Web::Engine, at: '/jobs'
    mount Searchjoy::Engine, at: '/searchjoy'
    match '/_dashboards/*path' => 'opensearch_dashboard#index', via: %i[get post put patch delete]
  end

  namespace :api do
    namespace :v1 do
      post '/graphql', to: 'graphql#execute'
      scope '/oni', as: 'oni', defaults: { format: 'json' } do
        get 'objects' => 'oni#objects'
        get 'object' => 'oni#object'
        get 'object/meta' => 'oni#object_meta'
        get 'stream' => 'oni#stream'
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
