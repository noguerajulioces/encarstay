# A one-off marketing email blast to the confirmed list. The body is authored in
# the admin with the Trix editor (ActionText). Delivery fans out one email per
# confirmed subscriber via a background job; each carries a List-Unsubscribe
# header. Sending is a one-way door — a sent campaign is locked.
class Campaign < ApplicationRecord
  has_rich_text :body

  enum :status, %w[ draft sending sent ].index_with(&:itself), default: :draft

  validates :subject, presence: true

  scope :chronologically, -> { order(created_at: :desc) }

  def editable?
    draft?
  end

  # Flip to sending and hand off to the background job (idempotent — only a draft
  # can be launched).
  def deliver!
    return false unless draft?
    update!(status: :sending)
    CampaignDeliveryJob.perform_later(self)
    true
  end
end
