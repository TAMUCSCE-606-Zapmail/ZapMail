Rails.application.routes.draw do
  root "templates#index"

  resources :templates do
    member do
      post :preview
      post :schedule
    end
    collection do
      post :verify_spreadsheet
      post :preview
    end
  end

  get 'signup', to: 'users#new'
  resources :users, only: [:create, :show, :edit, :update]

  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  get 'profile', to: 'users#show'
  get 'profile/edit', to: 'users#edit'
  patch 'profile', to: 'users#update'

  get "up" => "rails/health#show", as: :rails_health_check
end

