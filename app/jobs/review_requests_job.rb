class ReviewRequestsJob < ApplicationJob
  queue_as :default

  # Runs daily: closes out stays whose checkout has passed and invites each
  # guest to rate their stay.
  def perform
    Booking.awaiting_review_request.find_each(&:request_review!)
  end
end
