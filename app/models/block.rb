class Block < ApplicationRecord
  include OccupiesDates
  occupies_dates from: :starts_on, to: :ends_on

  belongs_to :property

  validates :starts_on, :ends_on, presence: true
  validate :ends_after_starts

  private
    def ends_after_starts
      return if starts_on.blank? || ends_on.blank?
      errors.add(:ends_on, "debe ser posterior al inicio") if ends_on <= starts_on
    end
end
