Nabu::Application.routes.draw do
  devise_for :users

  authenticate :user do
    root :to => 'home#dashboard'
  end
  root :to => 'home#index'

  resources :users
  resources :universities
  resources :collections
end
