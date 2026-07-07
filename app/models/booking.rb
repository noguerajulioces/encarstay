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

  validates :guest_name, :guest_email, presence: true
  validates :check_in, :check_out, presence: true
  validates :guests_count, numericality: { greater_than_or_equal_to: 1 }
  validate :check_out_after_check_in
  validate :dates_available, on: :create

  def nights
    return 0 if check_in.blank? || check_out.blank?
    (check_out - check_in).to_i
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

    def check_out_after_check_in
      return if check_in.blank? || check_out.blank?
      errors.add(:check_out, "debe ser posterior al check-in") if check_out <= check_in
    end

    def dates_available
      return if property.blank? || check_in.blank? || check_out.blank?
      return if check_out <= check_in

      unless property.available?(check_in, check_out)
        errors.add(:base, "Las fechas ya no están disponibles")
      end
    end
end
