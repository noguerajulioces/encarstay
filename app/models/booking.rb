class Booking < ApplicationRecord
  include OccupiesDates
  occupies_dates from: :check_in, to: :check_out

  belongs_to :property

  enum :status, %w[ pending confirmed completed cancelled ].index_with(&:itself), default: :pending
  enum :source, %w[ direct manual ].index_with(&:itself), default: :direct

  # Bookings that hold dates off the market. Cancelled frees them; completed is past.
  scope :occupying, -> { where(status: %w[ pending confirmed ]) }
  scope :chronologically, -> { order(:check_in) }

  before_validation :generate_code, on: :create
  before_validation :price, on: :create

  validates :guest_name, :guest_email, presence: true
  validates :check_in, :check_out, presence: true
  validates :guests_count, numericality: { greater_than_or_equal_to: 1 }
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }
  validate :check_out_after_check_in
  validate :within_capacity
  validate :meets_minimum_nights
  validate :dates_available, on: :create

  def nights
    return 0 if check_in.blank? || check_out.blank?
    (check_out - check_in).to_i
  end

  # Half the total, paid up front to hold the booking (seña).
  def deposit_cents
    (total_cents / 2.0).ceil
  end

  def confirm!
    update!(status: :confirmed, confirmed_at: Time.current)
  end

  def cancel!
    update!(status: :cancelled, cancelled_at: Time.current)
  end

  private
    def generate_code
      self.code ||= loop do
        candidate = "RES-#{SecureRandom.alphanumeric(4).upcase}"
        break candidate unless Booking.exists?(code: candidate)
      end
    end

    def price
      return if property.blank? || check_in.blank? || check_out.blank? || check_out <= check_in

      quote = property.quote(check_in, check_out)
      self.subtotal_cents = quote.subtotal_cents
      self.cleaning_fee_cents = quote.cleaning_fee_cents
      self.total_cents = quote.total_cents
      self.currency = property.currency
    end

    def check_out_after_check_in
      return if check_in.blank? || check_out.blank?
      errors.add(:check_out, :after_check_in) if check_out <= check_in
    end

    def within_capacity
      return if property.blank? || guests_count.blank?
      errors.add(:guests_count, :over_capacity) if guests_count > property.capacity
    end

    def meets_minimum_nights
      return if property.blank? || check_in.blank? || check_out.blank? || check_out <= check_in

      minimum = property.min_nights_on(check_in)
      errors.add(:base, :min_nights, count: minimum) if nights < minimum
    end

    def dates_available
      return if property.blank? || check_in.blank? || check_out.blank?
      return if check_out <= check_in

      errors.add(:base, :dates_unavailable) unless property.available?(check_in, check_out)
    end
end
