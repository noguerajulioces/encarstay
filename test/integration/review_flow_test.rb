require "test_helper"

class ReviewFlowTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @property = properties(:lago)
    @booking = past_stay
  end

  test "the daily job completes past stays and invites each guest once" do
    assert_enqueued_emails 1 do
      ReviewRequestsJob.perform_now
    end

    @booking.reload
    assert @booking.completed?
    assert @booking.review_requested_at.present?

    assert_no_enqueued_emails do
      ReviewRequestsJob.perform_now
    end
  end

  test "upcoming stays are not invited" do
    upcoming = @property.book!(check_in: Date.current + 10, check_out: Date.current + 13,
      guests_count: 2, guest_name: "Futuro", guest_email: "futuro@example.com", status: :confirmed)

    ReviewRequestsJob.perform_now
    assert upcoming.reload.confirmed?
    assert_nil upcoming.review_requested_at
  end

  test "a guest rates via the tokened link and it publishes only after admin approval" do
    token = @booking.generate_token_for(:review)

    get new_review_path(token)
    assert_response :success

    counted_before = @property.reviews_count
    assert_difference "Review.count", 1 do
      assert_enqueued_emails 1 do
        post review_path(token), params: { review: { rating: 4, body: "Muy linda estadía.", reviewer_location: "Asunción" } }
      end
    end

    review = @booking.reload.review
    assert_not review.approved?
    assert_equal @booking.guest_name, review.reviewer_name
    assert_equal @booking.check_out, review.stayed_on
    assert_equal counted_before, @property.reload.reviews_count, "pending reviews must not count"

    get property_path(@property.slug)
    assert_response :success
    assert_no_match "Muy linda estadía.", response.body

    review.approve!
    assert_equal counted_before + 1, @property.reload.reviews_count

    get property_path(@property.slug)
    assert_match "Muy linda estadía.", response.body
  end

  test "a booking can only be rated once" do
    token = @booking.generate_token_for(:review)
    post review_path(token), params: { review: { rating: 5 } }

    assert_no_difference "Review.count" do
      post review_path(token), params: { review: { rating: 1 } }
    end
    assert_equal 5, @booking.reload.review.rating
  end

  test "a tampered token is rejected" do
    get new_review_path("garbage-token")
    assert_response :gone
  end

  test "a booking that has not checked out yet cannot be rated" do
    upcoming = @property.book!(check_in: Date.current + 10, check_out: Date.current + 13,
      guests_count: 2, guest_name: "Futuro", guest_email: "futuro@example.com", status: :confirmed)

    get new_review_path(upcoming.generate_token_for(:review))
    assert_response :gone
  end

  test "the admin approves a pending review from the panel" do
    review = @booking.create_review!(property: @property, reviewer_name: @booking.guest_name,
      rating: 5, stayed_on: @booking.check_out)

    post admin_session_path, params: { email: "admin@example.com", password: "secret123" }
    get admin_property_reviews_path(@property)
    assert_response :success
    assert_match "Pendiente de aprobación", response.body

    post admin_property_review_approval_path(@property, review)
    assert review.reload.approved?
  end

  private
    # A confirmed stay whose checkout already passed. Past dates skip the
    # availability horizon, so create it directly.
    def past_stay
      @property.book!(check_in: Date.current - 5, check_out: Date.current - 2,
        guests_count: 2, guest_name: "Gustavo Guest", guest_email: "guest@example.com",
        status: :confirmed, confirmed_at: Time.current)
    end
end
