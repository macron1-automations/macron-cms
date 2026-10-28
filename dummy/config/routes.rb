Rails.application.routes.draw do
  mount Macron::Cms::Engine => "/cms"

  get "up" => "rails/health#show", as: :rails_health_check

  resources :articles, only: [ :show ]

  root "pages#index"
end
