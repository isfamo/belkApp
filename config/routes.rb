Rails.application.routes.draw do

  root 'home#index'
  get '/auth/salsify/callback' => 'salsify_session#create'

  scope :api,  module: :api do
    # resources :some_controller, only: [ :create ]
  end

  # send routing to angular
  get '*page', to: 'home#index'

end
