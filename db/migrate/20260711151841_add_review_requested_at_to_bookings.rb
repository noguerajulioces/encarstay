class AddReviewRequestedAtToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :review_requested_at, :datetime
  end
end
