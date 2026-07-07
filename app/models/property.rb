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

  private
    def set_slug
      self.slug = name.parameterize if slug.blank? && name.present?
    end
end
