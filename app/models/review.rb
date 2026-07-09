class Review < ApplicationRecord
  belongs_to :property

  scope :recent, -> { order(stayed_on: :desc, created_at: :desc) }

  validates :reviewer_name, presence: true
  validates :rating, numericality: { only_integer: true, in: 1..5 }

  # Keep the property's cached rating/count in step with its reviews. Runs after
  # commit so the aggregate reflects committed state, not a half-open transaction.
  after_save_commit    { property.recalculate_reviews! }
  after_destroy_commit { property.recalculate_reviews! }
end
