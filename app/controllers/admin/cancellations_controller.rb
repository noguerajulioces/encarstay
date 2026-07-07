class Admin::CancellationsController < Admin::BaseController
  def create
    @booking = Booking.find(params[:booking_id])
    @booking.cancel!
    redirect_to admin_booking_path(@booking), notice: "Reserva cancelada. Las fechas quedaron libres."
  end
end
