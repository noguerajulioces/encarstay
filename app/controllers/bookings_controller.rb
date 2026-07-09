class BookingsController < ApplicationController
  def new
    @property = Property.active.find_by!(slug: params[:property_slug])
    @booking = @property.bookings.build(
      check_in: parse_date(params[:check_in]),
      check_out: parse_date(params[:check_out]),
      guests_count: params[:guests].presence || 2
    )
    @quote = @property.quote(@booking.check_in, @booking.check_out)
  end

  def create
    @property = Property.active.find(booking_params[:property_id])
    return redirect_to(root_path) if spam?

    # Remember the language the guest booked in so their emails match it later.
    @booking = @property.book!(booking_params.except(:property_id).merge(locale: I18n.locale))
    BookingMailer.with(booking: @booking).guest_requested.deliver_later
    BookingMailer.with(booking: @booking).admin_requested.deliver_later
    redirect_to booking_path(@booking.code), notice: t("booking.flash_received")
  rescue ActiveRecord::RecordInvalid => error
    @booking = error.record
    @quote = @property.quote(@booking.check_in, @booking.check_out)
    render :new, status: :unprocessable_entity
  end

  def show
    @booking = Booking.find_by(code: params[:code].to_s.strip.upcase)
    redirect_to booking_lookup_path, alert: t("booking.not_found") unless @booking
  end

  # Dedicated "look up my reservation" page.
  def lookup
  end

  private
    def booking_params
      params.require(:booking).permit(:property_id, :check_in, :check_out, :guests_count,
        :guest_name, :guest_email, :guest_phone, :notes, :applied_discount_code)
    end

    # Honeypot: a hidden field real guests never fill. Bots do.
    def spam?
      params[:company].present?
    end
end
