module ApplicationHelper
  # Renders a JSON-LD structured-data block, escaping "<" so a stray "</script>"
  # in the data can't break out of the tag.
  def json_ld(data)
    tag.script(JSON.generate(data).gsub("<", "\\u003c").html_safe, type: "application/ld+json")
  end

  # The clean URL without query string — the SEO canonical for the current page.
  def canonical_url
    "#{request.base_url}#{request.path}"
  end

  # Amounts are stored in minor units (× 100). Guaraní shows no decimals; dollar shows two.
  def money(cents, currency)
    case currency
    when "USD"
      "US$ #{number_to_currency(cents / 100.0, unit: '', delimiter: ',', separator: '.', precision: 2)}"
    else
      "₲ #{number_with_delimiter(cents / 100, delimiter: '.')}"
    end
  end

  def nights_label(count)
    t("units.nights", count: count)
  end

  def guests_label(count)
    t("units.guests", count: count)
  end

  # Public path for a guide entry, routed by its kind.
  def guide_entry_path(entry)
    entry.event? ? event_path(entry) : attraction_path(entry)
  end

  # The current page's path rebuilt for another locale — used by the language
  # switcher and hreflang tags. Works off the raw path (not url_for) so it holds
  # up on any page, including non-GET renders. The default locale stays unprefixed.
  def path_for_locale(target)
    segments = request.path.split("/")
    segments.delete_at(1) if I18n.available_locales.map(&:to_s).include?(segments[1]) && segments[1] != I18n.default_locale.to_s
    stripped = segments.join("/")
    prefix = target.to_sym == I18n.default_locale ? "" : "/#{target}"
    path = "#{prefix}#{stripped}".sub(%r{\A/\z}, "").presence || "/"
    request.query_string.present? ? "#{path}?#{request.query_string}" : path
  end

  def full_url_for_locale(target)
    "#{request.base_url}#{path_for_locale(target)}"
  end

  def whatsapp_number
    ENV.fetch("WHATSAPP_NUMBER", "595981000000")
  end

  # Click-to-chat link, optionally with a prefilled message.
  def whatsapp_url(text = nil)
    base = "https://wa.me/#{whatsapp_number}"
    text.present? ? "#{base}?text=#{CGI.escape(text)}" : base
  end

  # Full weeks (Monday-first) covering a month, for rendering a calendar grid.
  def calendar_month_days(month)
    (month.beginning_of_month.beginning_of_week(:monday)..month.end_of_month.end_of_week(:monday)).to_a
  end

  def status_badge_classes(status)
    {
      "pending" => "bg-amber-100 text-amber-800",
      "confirmed" => "bg-emerald-100 text-emerald-800",
      "completed" => "bg-sand-200 text-sand-700",
      "cancelled" => "bg-rose-100 text-rose-700"
    }.fetch(status.to_s, "bg-sand-100 text-sand-600")
  end

  def status_label(status)
    t("booking.status.#{status}", default: status.to_s)
  end

  # Inline outline icons (heroicons-style, stroke = currentColor). Keeps the UI
  # icon set dependency-free and themable via text color. Star renders filled.
  ICON_PATHS = {
    pin: %(<path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/><path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1 1 15 0Z"/>),
    users: %(<path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z"/>),
    bed: %(<path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12h19.5M2.25 12V6.75A1.5 1.5 0 0 1 3.75 5.25h16.5a1.5 1.5 0 0 1 1.5 1.5V12m-19.5 0v6m19.5-6v6M6 9.75h4.5"/>),
    bath: %(<path stroke-linecap="round" stroke-linejoin="round" d="M3 12.75h18M4.5 12.75V6a2.25 2.25 0 0 1 4.34-.84M4.5 12.75v3a3.75 3.75 0 0 0 3.75 3.75h7.5A3.75 3.75 0 0 0 19.5 15.75v-3M6.75 19.5 6 21m11.25-1.5.75 1.5M7.5 6h1.5"/>),
    calendar: %(<path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5"/>),
    search: %(<path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z"/>),
    heart: %(<path stroke-linecap="round" stroke-linejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12Z"/>),
    sparkles: %(<path stroke-linecap="round" stroke-linejoin="round" d="M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09ZM18.259 8.715 18 9.75l-.259-1.035a3.375 3.375 0 0 0-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 0 0 2.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 0 0 2.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 0 0-2.456 2.456Z"/>),
    compass: %(<path stroke-linecap="round" stroke-linejoin="round" d="M9.348 14.652a3.75 3.75 0 0 1 0-5.304m5.304 0a3.75 3.75 0 0 1 0 5.304m-7.425 2.121a6.75 6.75 0 0 1 0-9.546m9.546 0a6.75 6.75 0 0 1 0 9.546M5.106 18.894c-3.808-3.807-3.808-9.98 0-13.788m13.788 0c3.808 3.807 3.808 9.98 0 13.788M12 12h.008v.008H12V12Z"/>),
    ticket: %(<path stroke-linecap="round" stroke-linejoin="round" d="M16.5 6v.75m0 3v.75m0 3v.75m0 3V18m-9-5.25h5.25M7.5 15h3M3.375 5.25c-.621 0-1.125.504-1.125 1.125v3.026a2.999 2.999 0 0 1 0 5.198v3.026c0 .621.504 1.125 1.125 1.125h17.25c.621 0 1.125-.504 1.125-1.125v-3.026a2.999 2.999 0 0 1 0-5.198V6.375c0-.621-.504-1.125-1.125-1.125H3.375Z"/>),
    arrow: %(<path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>),
    check: %(<path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5"/>),
    home: %(<path stroke-linecap="round" stroke-linejoin="round" d="m2.25 12 8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.5a.75.75 0 0 0 .75.75h4.5a.75.75 0 0 0 .75-.75V15a.75.75 0 0 1 .75-.75h3a.75.75 0 0 1 .75.75v5.25a.75.75 0 0 0 .75.75h4.5a.75.75 0 0 0 .75-.75V9.75"/>),
    clock: %(<path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>),
    x: %(<path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12"/>)
  }.freeze

  def icon(name, klass: "h-5 w-5", filled: false)
    path = ICON_PATHS[name.to_sym] or return
    tag.svg(path.html_safe, class: klass, viewBox: "0 0 24 24",
      fill: (filled ? "currentColor" : "none"),
      stroke: (filled ? "none" : "currentColor"),
      "stroke-width": 1.6, "aria-hidden": true, xmlns: "http://www.w3.org/2000/svg")
  end

  def star_icon(klass: "h-4 w-4")
    tag.svg(%(<path d="M11.48 3.499a.562.562 0 0 1 1.04 0l2.125 5.111a.563.563 0 0 0 .475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 0 0-.182.557l1.285 5.385a.562.562 0 0 1-.84.61l-4.725-2.885a.562.562 0 0 0-.586 0L6.982 20.54a.562.562 0 0 1-.84-.61l1.285-5.386a.562.562 0 0 0-.182-.557l-4.204-3.602a.563.563 0 0 1 .321-.988l5.518-.442a.563.563 0 0 0 .475-.345L11.48 3.5Z"/>).html_safe,
      class: klass, viewBox: "0 0 24 24", fill: "currentColor", "aria-hidden": true, xmlns: "http://www.w3.org/2000/svg")
  end
end
