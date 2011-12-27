Nabu::Application.routes.draw do
  devise_for :users

  authenticated :user do
    root :to => 'page#dashboard'
  end
  root :to => 'page#about'

  match '/about' => 'page#about'
  match '/contact' => 'page#contact'

  resources :users
  resources :universities
  resources :collections, :shallow => true do
    resources :items
  end
  resources :items, :only => :index
end
