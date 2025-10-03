# These two lines load the necessary components for the Sidekiq dashboard
require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do

  if Rails.env.development?
    mount Sidekiq::Web => '/sidekiq'
    # FIX: Add this line to mount the letter_opener UI
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  root "templates#index"

  resources :templates do
    member do
      post :preview
      post :schedule
    end
    collection do
      post :verify_spreadsheet
      # The duplicate 'preview' route has been removed from here
    end
  end

  # Routes for viewing automation history
  resources :automations, only: [:index, :show]

  # --- User and Session Routes ---
  get 'signup', to: 'users#new'
  resources :users, only: [:create] # Simplified to only what's needed for signup

  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  get 'profile', to: 'users#show'
  get 'profile/edit', to: 'users#edit'
  patch 'profile', to: 'users#update'

  get "up" => "rails/health#show", as: :rails_health_check
end
