class ReviewsController < ApplicationController
  before_action :set_booking

  def new
    @review = @booking.review || @booking.build_review(rating: 5)
  end

  def create
    return redirect_to new_review_path(params[:token]) if @booking.review

    @review = @booking.build_review(review_params.merge(
      property: @booking.property,
      reviewer_name: @booking.guest_name,
      stayed_on: @booking.check_out))

    if @review.save
      BookingMailer.with(review: @review).admin_review_submitted.deliver_later
      redirect_to new_review_path(params[:token])
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_booking
      @booking = Booking.find_by_token_for(:review, params[:token])
      render :invalid_link, status: :gone unless @booking&.reviewable?
    end

    def review_params
      params.require(:review).permit(:rating, :reviewer_location, :body)
    end
end
