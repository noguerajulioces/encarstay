class Admin::ConfirmationsController < Admin::BaseController
  def create
    @booking = Booking.find(params[:booking_id])
    @booking.confirm!
    BookingMailer.with(booking: @booking).confirmed.deliver_later
    redirect_to admin_booking_path(@booking), notice: "Reserva confirmada. Se avisó al huésped."
  end
end
