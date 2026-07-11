class BookingMailer < ApplicationMailer
  # Sent to the guest right after they submit the request — in the language they
  # booked in.
  def guest_requested
    @booking = params[:booking]
    I18n.with_locale(@booking.locale) do
      @locale_param = url_locale
      mail to: @booking.guest_email, subject: t("mailer.guest_requested.subject", code: @booking.code)
    end
  end

  # Sent to the admin(s) with the guest's contact and a one-click link to block the
  # dates on the Airbnb listing — the §7 mitigation for the ~2h sync window.
  def admin_requested
    @booking = params[:booking]
    @recipients = User.pluck(:email)
    mail to: @recipients, subject: "Nueva reserva #{@booking.code} · #{@booking.property.name}" if @recipients.any?
  end

  # Sent to the guest when the admin confirms the booking — in the language they
  # booked in.
  def confirmed
    @booking = params[:booking]
    I18n.with_locale(@booking.locale) do
      @locale_param = url_locale
      mail to: @booking.guest_email, subject: t("mailer.confirmed.subject", code: @booking.code)
    end
  end

  # Sent to the guest the day after checkout with a personal signed link to rate
  # the stay — in the language they booked in.
  def review_request
    @booking = params[:booking]
    I18n.with_locale(@booking.locale) do
      @locale_param = url_locale
      @review_token = @booking.generate_token_for(:review)
      mail to: @booking.guest_email, subject: t("mailer.review_request.subject", property: @booking.property.name)
    end
  end

  # Heads-up to the admin(s) that a guest review is waiting for approval.
  def admin_review_submitted
    @review = params[:review]
    @recipients = User.pluck(:email)
    mail to: @recipients, subject: "Nueva reseña pendiente de aprobación · #{@review.property.name}" if @recipients.any?
  end

  # Critical alert to the admin when an imported event collides with a direct booking.
  def collision_alert
    @booking = params[:booking]
    @event = params[:event]
    @recipients = User.pluck(:email)
    mail to: @recipients, subject: "⚠️ Colisión de calendario · #{@booking.property.name}" if @recipients.any?
  end

  private
    # Booking links in guest emails need the locale prefix; the default stays bare.
    def url_locale
      @booking.locale.to_sym == I18n.default_locale ? nil : @booking.locale
    end
end
