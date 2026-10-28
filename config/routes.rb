Macron::Cms::Engine.routes.draw do
  root to: "dashboard#index"
  resources :articles do
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
end
