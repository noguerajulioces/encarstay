class NewsletterMailer < ApplicationMailer
  # Double opt-in: asks the subscriber to confirm they want the list.
  def confirm
    @subscriber = params[:subscriber]
    I18n.with_locale(@subscriber.locale) do
      @locale_param = url_locale
      mail to: @subscriber.email, subject: t("mailer.newsletter.confirm.subject")
    end
  end

  # Sent once, right after confirmation — carries the welcome discount code and
  # the unsubscribe link.
  def welcome
    @subscriber = params[:subscriber]
    I18n.with_locale(@subscriber.locale) do
      @locale_param = url_locale
      mail to: @subscriber.email, subject: t("mailer.newsletter.welcome.subject")
    end
  end

  # A marketing campaign blast (see Campaign / CampaignDeliveryJob). Adds the
  # one-click List-Unsubscribe headers Gmail/Outlook expect on bulk mail.
  def campaign
    @campaign = params[:campaign]
    @subscriber = params[:subscriber]
    I18n.with_locale(@subscriber.locale) do
      @locale_param = url_locale
      @unsubscribe_url = newsletter_unsubscribe_url(@subscriber.unsubscribe_token, locale: @locale_param)
      headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
      headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
      mail to: @subscriber.email, subject: @campaign.subject
    end
  end

  # One-time re-engagement invite to a past guest (not yet a subscriber). The
  # personalised, signed join link is the single opt-in — clicking it is consent.
  def invitation
    @email = params[:email]
    @locale = params[:locale].to_s.presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale.to_s
    I18n.with_locale(@locale) do
      locale_param = @locale.to_sym == I18n.default_locale ? nil : @locale
      token = Rails.application.message_verifier(:newsletter_invite).generate(@email, expires_in: 30.days)
      @join_url = newsletter_join_url(token, locale: locale_param)
      mail to: @email, subject: t("mailer.newsletter.invitation.subject")
    end
  end

  private
    # Links in subscriber emails need the locale prefix; the default stays bare.
    def url_locale
      @subscriber.locale.to_sym == I18n.default_locale ? nil : @subscriber.locale
    end
end
