class SubscriptionsController < ApplicationController
  # Basic abuse throttle. Uses Rails.cache, so it's a no-op under the test
  # :null_store — the honeypot is the tested defence.
  rate_limit to: 5, within: 1.minute, only: :create

  # Footer + popup signup. The web response is identical in every case so we
  # never reveal which addresses already exist; only the server-side branch and
  # the email (if any) differ.
  def create
    @variant = params[:variant].presence_in(%w[ footer popup ]) || "footer"
    return respond_success if spam?

    @subscriber = Subscriber.find_or_initialize_by(email: normalized_email)
    process_subscription
    respond_success
  rescue ActiveRecord::RecordInvalid
    respond_invalid
  end

  # Double opt-in landing. Idempotent so link scanners / repeat clicks don't
  # re-issue the welcome discount.
  def confirm
    @subscriber = Subscriber.find_by(confirmation_token: params[:token])
    return render :invalid_token, status: :not_found unless @subscriber

    first_confirmation = !@subscriber.confirmed?
    @subscriber.confirm!
    NewsletterMailer.with(subscriber: @subscriber).welcome.deliver_later if first_confirmation
  end

  def unsubscribe
    @subscriber = Subscriber.find_by(unsubscribe_token: params[:token])
    return render :invalid_token, status: :not_found unless @subscriber

    @subscriber.unsubscribe!
  end

  # Landing for the past-guest invitation link. The signed token proves the guest
  # clicked their own personalised link, so this single action opts them in.
  def join
    email = Rails.application.message_verifier(:newsletter_invite).verify(params[:token])
    @subscriber = Subscriber.find_or_initialize_by(email: email)
    first_confirmation = !@subscriber.confirmed?
    if @subscriber.new_record?
      @subscriber.assign_attributes(locale: I18n.locale.to_s, source: "invitation")
      @subscriber.save!
    end
    @subscriber.confirm!
    NewsletterMailer.with(subscriber: @subscriber).welcome.deliver_later if first_confirmation
    render :confirm
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    render :invalid_token, status: :not_found
  end

  private
    def normalized_email
      params.dig(:subscriber, :email).to_s.strip.downcase
    end

    def process_subscription
      if @subscriber.new_record?
        @subscriber.assign_attributes(locale: I18n.locale.to_s, source: @variant)
        @subscriber.save!
        send_confirmation
      elsif @subscriber.pending?
        @subscriber.regenerate_confirmation_token
        send_confirmation
      elsif @subscriber.unsubscribed?
        @subscriber.resubscribe!
        send_confirmation
      end
      # confirmed: already on the list — send nothing, stay neutral.
    end

    def send_confirmation
      NewsletterMailer.with(subscriber: @subscriber).confirm.deliver_later
    end

    def respond_success
      respond_to do |format|
        format.turbo_stream { render :create }
        format.html { redirect_back fallback_location: root_path, notice: t("newsletter.check_email") }
      end
    end

    def respond_invalid
      respond_to do |format|
        format.turbo_stream { render :invalid, status: :unprocessable_entity }
        format.html { redirect_back fallback_location: root_path, alert: t("newsletter.invalid_email") }
      end
    end

    # Honeypot: a hidden field real people never fill. Bots do. Same convention
    # as BookingsController#spam?.
    def spam?
      params[:company].present?
    end
end
