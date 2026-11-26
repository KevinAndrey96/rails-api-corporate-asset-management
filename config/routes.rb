Rails.application.routes.draw do
  namespace :api do
    namespace :v1, defaults: { format: :json } do
      resources :employees
      resources :assets
      resources :assignments, only: %i[index show create] do
        patch :return, on: :member, action: :check_in
      end
      resources :alerts, only: :index
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
