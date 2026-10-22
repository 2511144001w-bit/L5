Rails.application.routes.draw do
  root "top#main"

  resources :users, only: [:index, :new, :create, :destroy] do
    resource :profile, only: [:show, :new, :create, :edit, :update, :destroy]
  end
  resources :tweets, only: [:create, :destroy]
  resources :likes, only: [:create, :destroy]

  get "/login", to: "top#login_form", as: :login
  post "/top/login", to: "top#login"
  delete "/logout", to: "top#logout", as: :logout
end
