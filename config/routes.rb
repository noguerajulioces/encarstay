Rails.application.routes.draw do
  # --- Public site ---
  # Spanish (the default) lives at the root; English and Portuguese are prefixed
  # (/en, /pt). The optional (:locale) segment is constrained so only those two
  # ever prefix a URL — "es" stays unprefixed.
  scope "(:locale)", locale: /en|pt/ do
    root "home#index"

    resource :search, only: :show
    resources :properties, only: %i[ index show ], param: :slug
    resources :events,      only: %i[ index show ], param: :slug
    resources :attractions, only: %i[ index show ], param: :slug, path: "things-to-do"
    resources :posts,       only: %i[ index show ], param: :slug, path: "blog"
    resources :bookings, only: %i[ new create show ], param: :code
    get "my-booking", to: "bookings#lookup", as: :booking_lookup
  end

  # Outgoing iCal feed consumed by Airbnb ("Import calendar"). Tokenized per property.
  get "calendars/:calendar_token/:slug", to: "calendars#show", as: :calendar_feed, defaults: { format: "ics" }

  get "sitemap.xml", to: "sitemaps#show", as: :sitemap, defaults: { format: "xml" }

  # --- Admin panel ---
  namespace :admin do
    root "dashboard#show"
    resource :session, only: %i[ new create destroy ]

    resources :bookings, only: %i[ index show new create ] do
      resource :confirmation, only: :create
      resource :cancellation, only: :create
    end

    resources :properties do
      resources :seasonal_rates, only: %i[ create destroy ]
      resources :photos, only: :destroy
      resources :reviews, except: :show
      resources :calendar_sources, only: %i[ create update destroy ] do
        resource :sync, only: :create
      end
    end

    resources :guide_entries, except: :show do
      resources :property_recommendations, only: %i[ create destroy ]
    end
    resources :posts, except: :show
    resources :categories, except: :show

    resources :blocks, only: %i[ create destroy ]
    resource :calendar, only: :show, controller: "calendar"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
