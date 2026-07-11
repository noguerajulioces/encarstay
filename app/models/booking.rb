class Booking < ApplicationRecord
  include OccupiesDates
  occupies_dates from: :check_in, to: :check_out

  # Welcome-code discount off the lodging subtotal (see Subscriber).
  DISCOUNT_RATE = 0.05

  belongs_to :property
  has_one :review, dependent: :nullify

  normalizes :applied_discount_code, with: ->(code) { code.to_s.strip.upcase.presence }

  enum :status, %w[ pending confirmed completed cancelled ].index_with(&:itself), default: :pending
  enum :source, %w[ direct manual ].index_with(&:itself), default: :direct

  # The signed link mailed to the guest after checkout — no account needed.
  generates_token_for :review, expires_in: 60.days

  # Bookings that hold dates off the market. Cancelled frees them; completed is past.
  scope :occupying, -> { where(status: %w[ pending confirmed ]) }
  scope :chronologically, -> { order(:check_in) }
  scope :awaiting_review_request, -> { confirmed.where(review_requested_at: nil).where(check_out: ...Date.current) }

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
  validate :discount_code_redeemable, on: :create

  def nights
    return 0 if check_in.blank? || check_out.blank?
    (check_out - check_in).to_i
  end

  # Half the total, paid up front to hold the booking (seña).
  def deposit_cents
    (total_cents / 2.0).ceil
  end

  def confirm!
    transaction do
      update!(status: :confirmed, confirmed_at: Time.current)
      redeem_discount!
    end
  end

  def cancel!
    update!(status: :cancelled, cancelled_at: Time.current)
  end

  # Marks the stay as completed and invites the guest to rate it.
  def request_review!
    update!(status: :completed, review_requested_at: Time.current)
    BookingMailer.with(booking: self).review_request.deliver_later
  end

  def reviewable?
    (confirmed? || completed?) && check_out <= Date.current
  end

  # The subscriber whose welcome code was applied, if it's still valid and unused.
  def discount_subscriber
    return nil if applied_discount_code.blank?
    Subscriber.confirmed.find_by(discount_code: applied_discount_code, discount_redeemed_at: nil)
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
      self.discount_cents = discount_subscriber ? (quote.subtotal_cents * DISCOUNT_RATE).round : 0
      self.total_cents = quote.total_cents - discount_cents
      self.currency = property.currency
    end

    def discount_code_redeemable
      return if applied_discount_code.blank?
      errors.add(:applied_discount_code, :invalid_discount) unless discount_subscriber
    end

    # Burn the welcome code once the booking is actually confirmed — a mere
    # request doesn't consume it.
    def redeem_discount!
      return if applied_discount_code.blank?
      Subscriber.where(discount_code: applied_discount_code, discount_redeemed_at: nil)
                .update_all(discount_redeemed_at: Time.current)
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
