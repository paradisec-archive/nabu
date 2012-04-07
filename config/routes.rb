Nabu::Application.routes.draw do
  opinio_model

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
    resources :items do
      get 'advanced_search', :on => :collection
      opinio
    end
  end
  resources :items, :only => :index
  resources :universities, :only => :create
end
