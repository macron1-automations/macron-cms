Macron::Cms::Engine.routes.draw do
  root to: "dashboard#index"
  resources :articles
  resources :content_types, only: %i[index show]
end
