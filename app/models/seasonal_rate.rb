class SeasonalRate < ApplicationRecord
  belongs_to :property

  scope :covering, ->(date) { where("starts_on <= ? AND ends_on >= ?", date, date) }

  validates :name, presence: true
  validates :starts_on, :ends_on, presence: true
  validates :price_per_night_cents, numericality: { greater_than_or_equal_to: 0 }
  validate :ends_after_starts

  private
    def ends_after_starts
      return if starts_on.blank? || ends_on.blank?
      errors.add(:ends_on, "debe ser posterior al inicio") if ends_on < starts_on
    end
end
