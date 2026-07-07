class BookingMailer < ApplicationMailer
  # Sent to the guest right after they submit the request.
  def guest_requested
    @booking = params[:booking]
    mail to: @booking.guest_email, subject: "Recibimos tu solicitud · #{@booking.code}"
  end

  # Sent to the admin(s) with the guest's contact and a one-click link to block the
  # dates on the Airbnb listing — the §7 mitigation for the ~2h sync window.
  def admin_requested
    @booking = params[:booking]
    @recipients = User.pluck(:email)
    mail to: @recipients, subject: "Nueva reserva #{@booking.code} · #{@booking.property.name}" if @recipients.any?
  end

  # Sent to the guest when the admin confirms the booking.
  def confirmed
    @booking = params[:booking]
    mail to: @booking.guest_email, subject: "Tu reserva #{@booking.code} está confirmada ✓"
  end

  # Critical alert to the admin when an imported event collides with a direct booking.
  def collision_alert
    @booking = params[:booking]
    @event = params[:event]
    @recipients = User.pluck(:email)
    mail to: @recipients, subject: "⚠️ Colisión de calendario · #{@booking.property.name}" if @recipients.any?
  end
end
