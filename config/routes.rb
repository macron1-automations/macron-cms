Macron::Cms::Engine.routes.draw do
  root to: "dashboard#index"
  resources :articles
end
