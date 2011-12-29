Nabu::Application.routes.draw do
  # These cause Rails to set up a connection to the production database, which isn't available during
  # assets:precompile on Heroku, so the following unless block skips setting up these routes only when
  # rake assets:precompile is being run.
  #
  # Could be a problem if the assets needed these to be loaded to compile properly; pretty sure they don't.
  unless ARGV.join.include? 'assets:precompile'
    ActiveAdmin.routes(self)

    devise_for :users
  end

  authenticated :user do
    root :to => 'page#dashboard'
  end
  root :to => 'page#about'

  match '/about' => 'page#about'
  match '/contact' => 'page#contact'

  resources :users
  resources :collections, :shallow => true do
    resources :items
  end
  resources :items, :only => :index
end
