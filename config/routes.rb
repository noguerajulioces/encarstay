Rails.application.routes.draw do
  # --- Public site ---
  root "home#index"

  resource :search, only: :show
  resources :properties, only: %i[ index show ], param: :slug
  resources :bookings, only: %i[ new create show ], param: :code

  # Outgoing iCal feed consumed by Airbnb ("Import calendar"). Tokenized per property.
  get "calendars/:calendar_token/:slug", to: "calendars#show", as: :calendar_feed, defaults: { format: "ics" }

  # --- Admin panel ---
  namespace :admin do
    root "dashboard#show"
    resource :session, only: %i[ new create destroy ]

    resources :bookings, only: %i[ index show ] do
      resource :confirmation, only: :create
      resource :cancellation, only: :create
    end

    resources :properties do
      resources :seasonal_rates, except: :show
      resources :calendar_sources, except: :show do
        resource :sync, only: :create
      end
    end

    resources :blocks, only: %i[ create destroy ]
    resource :calendar, only: :show
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
