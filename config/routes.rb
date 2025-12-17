Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication
  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  # Chat interface
  get "chat", to: "chat#index", as: :chat
  post "chat/message", to: "chat#message", as: :chat_message
  get "chat/search_clients", to: "chat#search_clients", as: :chat_search_clients
  get "chat/search_services", to: "chat#search_services", as: :chat_search_services
  post "chat/quick_register_service", to: "chat#quick_register_service", as: :chat_quick_register_service


  # Services (Quick Actions)
  resources :services, only: [ :index, :create, :destroy ] do
    member do
      post :use
    end
  end

  # Root route
  root "chat#index"
end
