Nabu::Application.routes.draw do
  devise_for :users

  root :to => 'home#index'

  resources :users
  resources :universities
end
