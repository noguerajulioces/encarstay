class Property < ApplicationRecord
  include Monetizable

  CURRENCIES = %w[ PYG USD ].freeze

  monetize :base_price, :cleaning_fee

  has_secure_token :calendar_token

  has_many :photos, -> { ordered }, dependent: :destroy
  has_many :seasonal_rates, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :blocks, dependent: :destroy
  has_many :calendar_sources, dependent: :destroy
  has_many :external_events, through: :calendar_sources
  has_many :property_recommendations, dependent: :destroy
  has_many :guide_entries, through: :property_recommendations
  has_many :reviews, dependent: :destroy
  has_many :property_amenities, dependent: :destroy
  has_many :amenities, through: :property_amenities

  scope :active, -> { where(active: true) }
  scope :accommodating, ->(guests) { where("capacity >= ?", guests.to_i) }
  scope :alphabetically, -> { order(:name) }

  before_validation :set_slug, on: :create

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :currency, inclusion: { in: CURRENCIES }
  validates :capacity, :min_nights, numericality: { greater_than_or_equal_to: 1 }
  validates :base_price_cents, :cleaning_fee_cents, numericality: { greater_than_or_equal_to: 0 }

  # The golden rule: a property is available for a stay when nothing on the market
  # overlaps it — no active booking, no manual block, no imported external event.
  def available?(check_in, check_out)
    bookings.occupying.overlapping(check_in, check_out).none? &&
      blocks.overlapping(check_in, check_out).none? &&
      external_events.overlapping(check_in, check_out).none?
  end

  # Creates a booking under a row lock so the availability re-check and the insert
  # happen atomically — no two guests can win the same dates in a race.
  def book!(attributes)
    with_lock do
      bookings.create!(attributes)
    end
  end

  def quote(check_in, check_out)
    Quote.new(self, check_in, check_out)
  end

  # The set of nights taken off the market between two dates — used to paint the
  # availability calendar. Half-open, so a check-out day is not counted occupied.
  def occupied_dates(from = Date.current, to = Date.current + 4.months)
    spans  = bookings.occupying.pluck(:check_in, :check_out)
    spans += blocks.pluck(:starts_on, :ends_on)
    spans += external_events.pluck(:starts_on, :ends_on)

    spans.each_with_object(Set.new) do |(starts_on, ends_on), dates|
      (starts_on...ends_on).each { |date| dates << date if date >= from && date < to }
    end
  end

  # Per-date minimum stay for the availability window, listing only the days a
  # season raises above the property's floor — the base covers everything else.
  # Keyed by ISO date so the calendar picker can enforce it as you select.
  def min_nights_overrides(from = Date.current, to = Date.current + 4.months)
    seasonal_rates.where("ends_on >= ? AND starts_on < ?", from, to).each_with_object({}) do |rate, map|
      next unless rate.min_nights.to_i > min_nights

      span = ([ rate.starts_on, from ].max)..([ rate.ends_on, to - 1 ].min)
      span.each { |date| map[date.iso8601] = [ map[date.iso8601].to_i, rate.min_nights ].max }
    end
  end

  def cover_photo
    photos.detect { |photo| photo.image.attached? }
  end

  # Cached review aggregates, kept fresh by Review's after_commit callbacks. The
  # cache lives on the row so listing grids don't fan out a query per card.
  def recalculate_reviews!
    scope = reviews.reset
    update_columns(reviews_count: scope.count, rating_cache: scope.average(:rating))
  end

  def rated?
    reviews_count.positive?
  end

  def rating
    rating_cache
  end

  # A property earns Airbnb's "guest favourite" badge once it has a solid body of
  # reviews and a near-perfect average.
  def guest_favorite?
    rated? && rating_cache.to_f >= 4.9 && reviews_count >= 5
  end

  # Site-wide aggregates for the single-operator host card.
  def self.aggregate_rating
    where("reviews_count > 0").average(:rating_cache)
  end

  def self.total_reviews
    sum(:reviews_count)
  end

  def coordinates?
    latitude.present? && longitude.present?
  end

  # Great-circle distance in kilometres between this property and a point, via the
  # haversine formula. Straight-line, not a street route — enough to say "~1.2 km
  # from the Costanera" without needing a routing service.
  def distance_km_to(lat, lng)
    return nil unless coordinates? && lat.present? && lng.present?

    lat1 = latitude.to_f
    lng1 = longitude.to_f
    lat2 = lat.to_f
    lng2 = lng.to_f

    rad = Math::PI / 180
    dlat = (lat2 - lat1) * rad
    dlng = (lng2 - lng1) * rad
    a = (Math.sin(dlat / 2)**2) +
        (Math.cos(lat1 * rad) * Math.cos(lat2 * rad) * (Math.sin(dlng / 2)**2))
    6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  end

  # The nightly rate in effect on a given date: the covering seasonal rate, or the
  # base price when no season applies.
  def rate_for(date)
    seasonal_rates.covering(date).order(:starts_on).pick(:price_per_night_cents) || base_price_cents
  end

  # The minimum stay in effect on a given date: the covering season may raise it
  # above the property's floor.
  def min_nights_on(date)
    [ seasonal_rates.covering(date).order(:starts_on).pick(:min_nights), min_nights ].compact.max
  end

  def to_param
    slug
  end

  private
    def set_slug
      self.slug = name.parameterize if slug.blank? && name.present?
    end
end
