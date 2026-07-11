class Review < ApplicationRecord
  belongs_to :property
  belongs_to :booking, optional: true

  scope :recent, -> { order(stayed_on: :desc, created_at: :desc) }
  scope :approved, -> { where.not(approved_at: nil) }
  scope :pending_approval, -> { where(approved_at: nil) }

  validates :reviewer_name, presence: true
  validates :rating, numericality: { only_integer: true, in: 1..5 }
  validates :booking_id, uniqueness: true, allow_nil: true

  # Keep the property's cached rating/count in step with its reviews. Runs after
  # commit so the aggregate reflects committed state, not a half-open transaction.
  after_save_commit    { property.recalculate_reviews! }
  after_destroy_commit { property.recalculate_reviews! }

  def approved?
    approved_at.present?
  end

  def approve!
    update!(approved_at: Time.current)
  end
end
