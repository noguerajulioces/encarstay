class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :switch_locale

  private
    # The route only ever hands us en/pt (es is unprefixed), so params[:locale]
    # is trustworthy; anything else falls back to the default.
    def switch_locale(&action)
      I18n.with_locale(params[:locale] || I18n.default_locale, &action)
    end

    # Carry the current locale into every generated URL so links stay in-language.
    # The default locale is unprefixed, so it maps to nil (no /es, no ?locale=…).
    def default_url_options
      { locale: (I18n.locale == I18n.default_locale ? nil : I18n.locale) }
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue ArgumentError
      nil
    end
end
