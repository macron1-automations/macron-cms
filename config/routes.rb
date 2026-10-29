Macron::Cms::Engine.routes.draw do
  root to: "dashboard#index"
  resources :articles do
    member do
      delete :purge_background_image
    end
    resources :article_contents, only: %i[create update destroy] do
      member do
        patch :move
      end
      collection do
        patch :reorder
      end
    end
  end
  resources :content_types, only: %i[index show]

  namespace :api do
    namespace :v1 do
      resources :content_types, only: %i[index]
      resources :articles, only: %i[create show update]
    end
  end
end
