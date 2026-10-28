Rails.application.routes.draw do
  devise_for :users
  mount Macron::Cms::Engine => "/cms"

  get "up" => "rails/health#show", as: :rails_health_check

  resources :articles, only: [ :index, :show ]

  root "pages#index"
end
