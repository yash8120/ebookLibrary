Rails.application.routes.draw do
  namespace :api do
    resources :ebooks, only: [:index, :show, :create, :destroy] do
      collection do
        get :search
      end
      member do
        get :download
      end
    end
  end

  get "/up" => "rails/health#show", as: :rails_health_check
end
