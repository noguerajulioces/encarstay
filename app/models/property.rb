class Property < ApplicationRecord
  CURRENCIES = %w[ PYG USD ].freeze

  has_secure_token :calendar_token

  has_many :photos, -> { ordered }, dependent: :destroy
  has_many :seasonal_rates, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :blocks, dependent: :destroy
  has_many :calendar_sources, dependent: :destroy
  has_many :external_events, through: :calendar_sources

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

  def cover_photo
    photos.detect { |photo| photo.image.attached? }
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
