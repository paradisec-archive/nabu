Nabu::Application.routes.draw do

  # The ActiveAdmin routes cause Rails to set up a connection to the
  # production database, which isn't available during
  # assets:precompile on Heroku, so the following unless block skips
  # setting up these routes only when rake assets:precompile is
  # being run.
  #
  # Could be a problem if the assets needed these to be loaded to
  # compile properly; pretty sure they don't.
  break if ARGV.join.include? 'assets:precompile'

  ActiveAdmin.routes(self)

  devise_for :users

  authenticated :user do
    root :to => 'page#dashboard'
  end
  root :to => 'page#about'

  match '/about' => 'page#about'
  match '/contact' => 'page#contact'

  resources :users
  resources :collections, :shallow => true do
    get 'advanced_search', :on => :collection
    match 'bulk_update' => 'collections#bulk_edit', :on => :collection, :via => :get
    match 'bulk_update' => 'collections#bulk_update', :on => :collection, :via => :put
    resources :items do
      get 'advanced_search', :on => :collection
      match 'bulk_update' => 'collections#bulk_edit', :on => :collection, :via => :get
      match 'bulk_update' => 'collections#bulk_update', :on => :collection, :via => :put
    end
  end

  resources :comments, :shallow => true do
    match 'approve' => 'comments#approve', :on => :member, :via => :post
    match 'spam'    => 'comments#spam',    :on => :member, :via => :post
  end
  resources :items, :only => :index
  resources :universities, :only => :create
end
