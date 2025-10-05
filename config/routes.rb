# These two lines load the necessary components for the Sidekiq dashboard
require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  get "pages/home"
  # Mount developer tools only in the development environment for security
  if Rails.env.development?
    mount Sidekiq::Web => '/sidekiq'
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Defines the root path route ("/")
  # root "templates#index"
  root "pages#home"

  resources :templates do
    member do
      post :preview
      post :schedule
      post :duplicate
    end
    collection do
      post :verify_spreadsheet
    end
  end

  # Routes for viewing automation history
  resources :automations, only: [:index, :show]

  # --- User and Session Routes ---
  get 'signup', to: 'users#new'
  # This single line handles create, show, edit, and update for users
  resources :users, only: [:create, :show, :edit, :update]

  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  # Profile routes that map to the users controller
  get 'profile', to: 'users#show'
  get 'profile/edit', to: 'users#edit'
  patch 'profile', to: 'users#update'

  # Health check route
  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.test? || Rails.env.development?
    get "/raise_error_test", to: "errors#raise_test"
    get "/protected_test", to: "test#protected_action"
  end
end
