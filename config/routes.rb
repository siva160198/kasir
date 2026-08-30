Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  namespace :api do
    namespace :v1 do
      get "status", to: "status#show"
      get "readiness", to: "readiness#show"
      get "csrf", to: "csrf#show"
      resource :store_profile, only: :show do
        get :logo
      end
      post "csp_reports", to: "csp_reports#create"
      resource :password_reset, only: %i[show create update]
      resource :registration, only: :create
      resource :email_revert, only: :create
      resource :session, only: %i[show create destroy] do
        post :verify_otp
        post :resend_otp
        post :passkey_options
        post :passkey
      end
      resources :sessions, only: %i[index destroy], controller: :devices do
        delete :others, on: :collection, action: :destroy_others
      end
      resource :profile, only: %i[show update destroy] do
        get :avatar
      end
      resource :account_security, only: :show, controller: :account_security do
        patch :password
        post :request_email
        post :verify_email
        post :request_recovery_codes
        post :verify_recovery_codes
        post :request_totp
        post :verify_totp
        delete :disable_totp
      end
      resources :passkeys, only: %i[create destroy] do
        post :options, on: :collection
      end
      resource :step_up, only: :create do
        post :verify
      end

      namespace :admin do
        get "dashboard", to: "dashboard#show"
        resources :users, only: %i[index show update]
        resources :roles, only: %i[index show create update destroy]
        resources :categories, only: %i[index show create update destroy]
        resources :products, only: %i[index show create update destroy]
        resources :inventory, only: :index do
          get :alerts, on: :collection
          post :create_drafts, on: :collection
          patch :preferred_supplier, on: :member
        end
        resources :stock_movements, only: %i[index create] do
          get :adjustment, on: :member, action: :show
        end
        resources :cashier_shifts, only: %i[index create] do
          get :current, on: :collection
          patch :close, on: :member
          post :cash_movement, on: :member
        end
        resources :sales, only: %i[index show create] do
          get :catalog, on: :collection
          resources :refunds, only: :create, controller: "sale_refunds"
        end
        resources :sale_refunds, only: [] do
          patch :approve, on: :member
          patch :reject, on: :member
        end
        resource :report, only: :show do
          get :export
        end
        resources :suppliers, only: %i[index show create update destroy]
        resources :purchase_orders, only: %i[index show create update] do
          post :receive, on: :member
          patch :cancel, on: :member
        end
        resource :store_setting, only: %i[show update]
        resources :audit_logs, only: :index
        resources :approvals, only: %i[index update]
        resources :jobs, only: %i[index destroy] do
          post :retry, on: :member
        end
        resource :api_docs, only: :show
      end
    end
  end

  match "/api/*unmatched", to: "api_errors#not_found", via: :all

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "*path", to: "spa#index", constraints: ->(request) do
    !request.path.start_with?("/api", "/rails", "/letter_opener", "/frontend")
  end
  root "spa#index"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
