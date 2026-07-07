class Admin::BookingsController < Admin::BaseController
  def index
    @properties = Property.alphabetically
    @bookings = Booking.includes(:property).order(created_at: :desc)
    @bookings = @bookings.where(status: params[:status]) if params[:status].present?
    @bookings = @bookings.where(property_id: params[:property_id]) if params[:property_id].present?
  end

  def show
    @booking = Booking.find(params[:id])
  end

  def new
    @properties = Property.alphabetically
    @booking = Booking.new(check_in: params[:check_in], check_out: params[:check_out], guests_count: 1)
  end

  # Manual booking — a reservation the admin took by phone/WhatsApp.
  def create
    property = Property.find(booking_params[:property_id])
    @booking = property.book!(booking_params.except(:property_id).merge(source: :manual))
    redirect_to admin_booking_path(@booking), notice: "Reserva manual creada."
  rescue ActiveRecord::RecordInvalid => error
    @booking = error.record
    @properties = Property.alphabetically
    render :new, status: :unprocessable_entity
  end

  private
    def booking_params
      params.require(:booking).permit(:property_id, :check_in, :check_out, :guests_count,
        :guest_name, :guest_email, :guest_phone, :notes)
    end
end
