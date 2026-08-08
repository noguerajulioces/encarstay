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
      "Gs. #{number_with_delimiter(cents / 100, delimiter: '.')}"
    end
  end

  # Botones del sitio público. Variantes: :primary (verde sólido), :ghost
  # (borde neutro), :white (para fondos oscuros). `extra` es para layout
  # (ancho, márgenes) — no pasar utilidades de display ("hidden"): chocan con
  # el inline-flex de la base y gana el orden de compilación del CSS, no el
  # del atributo; envolver en un wrapper responsivo en su lugar.
  def btn_classes(variant = :primary, extra = nil)
    base = "inline-flex cursor-pointer items-center justify-center gap-2 rounded-xl px-6 py-3 text-base font-semibold transition-colors"
    variants = {
      primary: "bg-brand-500 text-white hover:bg-brand-600",
      ghost: "border border-sand-300 text-sand-800 hover:bg-sand-100",
      white: "bg-white text-sand-900 hover:bg-sand-100"
    }
    [ base, variants.fetch(variant), extra ].compact.join(" ")
  end

  def nights_label(count)
    t("units.nights", count: count)
  end

  # "2" o "1,5" — los medios baños (toilette sin ducha) cuentan 0,5.
  def bathrooms_display(value)
    number_with_precision(value, precision: 1, strip_insignificant_zeros: true, locale: I18n.locale)
  end

  # Distancia legible para el comparador: metros redondeados bajo el kilómetro,
  # un decimal (coma en es/pt) de ahí en adelante.
  def distance_label(km)
    return if km.blank?

    if km < 1
      "#{(km * 1000).round(-1).to_i} m"
    else
      "#{number_with_precision(km, precision: 1, locale: I18n.locale)} km"
    end
  end

  def guests_label(count)
    t("units.guests", count: count)
  end

  # Public path for a guide entry, routed by its kind.
  def guide_entry_path(entry)
    entry.event? ? event_path(entry) : attraction_path(entry)
  end

  # Trix only offers one heading level and emits <h1>. Demote those to <h2> so a
  # rendered article keeps a single top-level <h1> (its title) — cleaner for SEO.
  def demote_headings(html)
    html.to_s.gsub(%r{(</?)h1\b}, '\1h2').html_safe
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

  # Simple round flags for the language switcher (es = Spain, en = USA,
  # pt = Brazil), drawn as inline SVG so they render everywhere (emoji flags
  # don't show on Windows). Circular clip comes from the wrapping span.
  FLAG_SVGS = {
    es: %(<rect width="24" height="24" fill="#AA151B"/><rect y="6" width="24" height="12" fill="#F1BF00"/>),
    en: %(<rect width="24" height="24" fill="#fff"/><g fill="#B22234"><rect width="24" height="1.85"/><rect y="3.7" width="24" height="1.85"/><rect y="7.4" width="24" height="1.85"/><rect y="11.1" width="24" height="1.85"/><rect y="14.8" width="24" height="1.85"/><rect y="18.5" width="24" height="1.85"/><rect y="22.2" width="24" height="1.8"/></g><rect width="10.5" height="9.25" fill="#3C3B6E"/><g fill="#fff"><circle cx="2" cy="1.8" r=".7"/><circle cx="5" cy="1.8" r=".7"/><circle cx="8" cy="1.8" r=".7"/><circle cx="3.5" cy="3.7" r=".7"/><circle cx="6.5" cy="3.7" r=".7"/><circle cx="2" cy="5.6" r=".7"/><circle cx="5" cy="5.6" r=".7"/><circle cx="8" cy="5.6" r=".7"/><circle cx="3.5" cy="7.5" r=".7"/><circle cx="6.5" cy="7.5" r=".7"/></g>),
    pt: %(<rect width="24" height="24" fill="#009C3B"/><polygon points="12,2.5 21.5,12 12,21.5 2.5,12" fill="#FFDF00"/><circle cx="12" cy="12" r="4.3" fill="#002776"/>)
  }.freeze

  def flag_icon(locale, klass: "h-5 w-5")
    body = FLAG_SVGS[locale.to_sym] or return
    tag.span(
      tag.svg(body.html_safe, viewBox: "0 0 24 24", class: "h-full w-full", preserveAspectRatio: "xMidYMid slice"),
      class: "inline-block shrink-0 overflow-hidden rounded-full #{klass}",
      style: "box-shadow: inset 0 0 0 1px rgba(0,0,0,0.12)"
    )
  end

  def whatsapp_number
    Setting.current.whatsapp_number.presence || ENV.fetch("WHATSAPP_NUMBER", "595981000000")
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
    external_link: %(<path stroke-linecap="round" stroke-linejoin="round" d="M13.5 6H5.25A2.25 2.25 0 0 0 3 8.25v10.5A2.25 2.25 0 0 0 5.25 21h10.5A2.25 2.25 0 0 0 18 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25"/>),
    check: %(<path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5"/>),
    home: %(<path stroke-linecap="round" stroke-linejoin="round" d="m2.25 12 8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.5a.75.75 0 0 0 .75.75h4.5a.75.75 0 0 0 .75-.75V15a.75.75 0 0 1 .75-.75h3a.75.75 0 0 1 .75.75v5.25a.75.75 0 0 0 .75.75h4.5a.75.75 0 0 0 .75-.75V9.75"/>),
    clock: %(<path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>),
    envelope: %(<path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 0 1-2.25 2.25h-15a2.25 2.25 0 0 1-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25m19.5 0v.243a2.25 2.25 0 0 1-1.07 1.916l-7.5 4.615a2.25 2.25 0 0 1-2.36 0L3.32 8.91a2.25 2.25 0 0 1-1.07-1.916V6.75"/>),
    x: %(<path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12"/>),
    chevron_left: %(<path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5"/>),
    chevron_right: %(<path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5"/>),
    chevron_down: %(<path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5"/>),
    info: %(<path stroke-linecap="round" stroke-linejoin="round" d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z"/>),
    grid: %(<path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6A2.25 2.25 0 0 1 6 3.75h2.25A2.25 2.25 0 0 1 10.5 6v2.25a2.25 2.25 0 0 1-2.25 2.25H6a2.25 2.25 0 0 1-2.25-2.25V6ZM3.75 15.75A2.25 2.25 0 0 1 6 13.5h2.25a2.25 2.25 0 0 1 2.25 2.25V18a2.25 2.25 0 0 1-2.25 2.25H6A2.25 2.25 0 0 1 3.75 18v-2.25ZM13.5 6a2.25 2.25 0 0 1 2.25-2.25H18A2.25 2.25 0 0 1 20.25 6v2.25A2.25 2.25 0 0 1 18 10.5h-2.25a2.25 2.25 0 0 1-2.25-2.25V6ZM13.5 15.75a2.25 2.25 0 0 1 2.25-2.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25 0 0 1 18 20.25h-2.25A2.25 2.25 0 0 1 13.5 18v-2.25Z"/>),

    # Header / navigation.
    globe: %(<path stroke-linecap="round" stroke-linejoin="round" d="M12 21a9.004 9.004 0 0 0 8.716-6.747M12 21a9.004 9.004 0 0 1-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 0 1 7.843 4.582M12 3a8.997 8.997 0 0 0-7.843 4.582m15.686 0A11.953 11.953 0 0 1 12 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0 1 21 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0 1 12 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 0 1 3 12c0-1.605.42-3.113 1.157-4.418"/>),
    menu: %(<path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"/>),
    user: %(<path stroke-linecap="round" stroke-linejoin="round" d="M17.982 18.725A7.488 7.488 0 0 0 12 15.75a7.488 7.488 0 0 0-5.982 2.975m11.963 0A9 9 0 1 0 6.02 18.725m11.963 0A8.966 8.966 0 0 1 12 21a8.966 8.966 0 0 1-5.982-2.275M15 9.75a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/>),

    # Laurel branch (guest-favourite wreath). Mirror the right side with -scale-x-100.
    laurel: %(<path stroke-linecap="round" stroke-linejoin="round" d="M18 3c-6 2-9 7-9 13 0 2 .3 3.8 1 5.5M16 6c-.8 1.5-2.4 2.2-4 2M14.5 9.5c-.7 1.6-2.2 2.5-3.9 2.4M13 13.5c-.6 1.6-2 2.6-3.7 2.7M11.2 17.6c-.4 1.6-1.7 2.8-3.3 3.1"/>),

    # Star — single path, no explicit fill, so icon(:star, filled: true) fills it.
    star: %(<path d="M11.48 3.5a.562.562 0 0 1 1.04 0l2.125 5.11a.563.563 0 0 0 .475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 0 0-.182.557l1.285 5.385a.562.562 0 0 1-.84.61l-4.725-2.885a.562.562 0 0 0-.586 0L6.982 20.54a.562.562 0 0 1-.84-.61l1.285-5.386a.562.562 0 0 0-.182-.557l-4.204-3.602a.563.563 0 0 1 .321-.988l5.518-.442a.563.563 0 0 0 .475-.345L11.48 3.5Z"/>),

    # Amenity icons (heroicons-style outlines).
    wifi: %(<path stroke-linecap="round" stroke-linejoin="round" d="M8.288 15.038a5.25 5.25 0 0 1 7.424 0M5.106 11.856c3.807-3.808 9.98-3.808 13.788 0M1.924 8.674c5.565-5.565 14.587-5.565 20.152 0M12.53 18.22l-.53.53-.53-.53a.75.75 0 0 1 1.06 0Z"/>),
    tv: %(<path stroke-linecap="round" stroke-linejoin="round" d="M6 20.25h12m-7.5-3v3m3-3v3m-10.125-3h17.25c.621 0 1.125-.504 1.125-1.125V4.875c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125Z"/>),
    fire: %(<path stroke-linecap="round" stroke-linejoin="round" d="M15.362 5.214A8.252 8.252 0 0 1 12 21 8.25 8.25 0 0 1 6.038 7.047 8.287 8.287 0 0 0 9 9.601a8.983 8.983 0 0 1 3.361-6.867 8.21 8.21 0 0 0 3 2.48Z"/><path stroke-linecap="round" stroke-linejoin="round" d="M12 18a3.75 3.75 0 0 0 .495-7.467 5.99 5.99 0 0 0-1.925 3.546 5.974 5.974 0 0 1-2.133-1A3.75 3.75 0 0 0 12 18Z"/>),
    key: %(<path stroke-linecap="round" stroke-linejoin="round" d="M15.75 5.25a3 3 0 0 1 3 3m3 0a6 6 0 0 1-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5 17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1 .43-1.563A6 6 0 1 1 21.75 8.25Z"/>),
    shield: %(<path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75 11.25 15 15 9.75m-3-7.036A11.959 11.959 0 0 1 3.598 6 11.99 11.99 0 0 0 3 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285Z"/>),
    snowflake: %(<path stroke-linecap="round" stroke-linejoin="round" d="M12 2.25v19.5M4.6 6.75l14.8 10.5M19.4 6.75 4.6 17.25M9 3.75 12 6l3-2.25M4.5 9.4l.4 3.6-3 1.9M19.5 9.4l-.4 3.6 3 1.9M9 20.25 12 18l3 2.25"/>),
    workspace: %(<path stroke-linecap="round" stroke-linejoin="round" d="M9 17.25v1.007a3 3 0 0 1-.879 2.122L7.5 21h9l-.621-.621A3 3 0 0 1 15 18.257V17.25m6-12V15a2.25 2.25 0 0 1-2.25 2.25H5.25A2.25 2.25 0 0 1 3 15V5.25m18 0A2.25 2.25 0 0 0 18.75 3H5.25A2.25 2.25 0 0 0 3 5.25m18 0V12a2.25 2.25 0 0 1-2.25 2.25H5.25A2.25 2.25 0 0 1 3 12V5.25"/>),
    car: %(<path stroke-linecap="round" stroke-linejoin="round" d="M3 13.5 4.5 9a2.25 2.25 0 0 1 2.134-1.5h10.732A2.25 2.25 0 0 1 19.5 9L21 13.5m-18 0v4.5a.75.75 0 0 0 .75.75H6a.75.75 0 0 0 .75-.75V16.5h10.5V18a.75.75 0 0 0 .75.75h2.25a.75.75 0 0 0 .75-.75v-4.5m-18 0h18M6.75 16.5a.75.75 0 1 1 0-1.5.75.75 0 0 1 0 1.5Zm10.5 0a.75.75 0 1 1 0-1.5.75.75 0 0 1 0 1.5Z"/>),
    washer: %(<path stroke-linecap="round" stroke-linejoin="round" d="M6 3.75h12a1.5 1.5 0 0 1 1.5 1.5v13.5a1.5 1.5 0 0 1-1.5 1.5H6a1.5 1.5 0 0 1-1.5-1.5V5.25A1.5 1.5 0 0 1 6 3.75Z"/><path stroke-linecap="round" stroke-linejoin="round" d="M12 9.75a3.75 3.75 0 1 0 0 7.5 3.75 3.75 0 0 0 0-7.5ZM7.5 6.75h.008v.008H7.5V6.75Z"/>),
    pool: %(<path stroke-linecap="round" stroke-linejoin="round" d="M2.25 15.75c1.5 0 1.5 1.2 3 1.2s1.5-1.2 3-1.2 1.5 1.2 3 1.2 1.5-1.2 3-1.2 1.5 1.2 3 1.2 1.5-1.2 3-1.2M2.25 12c1.5 0 1.5 1.2 3 1.2s1.5-1.2 3-1.2 1.5 1.2 3 1.2 1.5-1.2 3-1.2 1.5 1.2 3 1.2 1.5-1.2 3-1.2"/>),
    kitchen: %(<path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v6.75a2.25 2.25 0 0 0 4.5 0V3M9 9.75V21M15.75 3c-1.243 0-2.25 1.511-2.25 3.375S14.507 9.75 15.75 9.75V21"/>),
    paw: %(<path stroke-linecap="round" stroke-linejoin="round" d="M12 13.5c-2.07 0-3.75 1.454-3.75 3.25 0 1.243 1.007 1.9 2.077 1.9.75 0 1.148-.4 1.673-.4s.923.4 1.673.4c1.07 0 2.077-.657 2.077-1.9 0-1.796-1.68-3.25-3.75-3.25ZM7.125 11.25a1.125 1.125 0 1 0 0-2.25 1.125 1.125 0 0 0 0 2.25ZM16.875 11.25a1.125 1.125 0 1 0 0-2.25 1.125 1.125 0 0 0 0 2.25ZM10.125 8.25a1.125 1.125 0 1 0 0-2.25 1.125 1.125 0 0 0 0 2.25ZM13.875 8.25a1.125 1.125 0 1 0 0-2.25 1.125 1.125 0 0 0 0 2.25Z"/>)
  }.freeze

  def icon(name, klass: "h-5 w-5", filled: false)
    path = ICON_PATHS[name.to_sym] or return
    tag.svg(path.html_safe, class: klass, viewBox: "0 0 24 24",
      fill: (filled ? "currentColor" : "none"),
      stroke: (filled ? "none" : "currentColor"),
      "stroke-width": 1.6, "aria-hidden": true, xmlns: "http://www.w3.org/2000/svg")
  end

  # Amenity glyph by its icon key, falling back to a check so an unknown key
  # never renders blank.
  def amenity_icon(key, klass: "h-6 w-6")
    icon(key.to_sym, klass: klass) || icon(:check, klass: klass)
  end

  # Marks for the handful of sites our guide entries link out to, drawn inline
  # like the rest of the icon set. Hotlinking real favicons would hand every
  # visitor's IP to Facebook or Google before they click anything — and resolve
  # to a blurry 16px sprite when it resolves at all. These paths are solid, so
  # they take the brand colour instead of currentColor.
  BRAND_MARKS = {
    "facebook.com" => { color: "#1877F2", path: %(<path d="M9.101 23.691v-7.98H6.627v-3.667h2.474v-1.58c0-4.085 1.848-5.978 5.858-5.978.401 0 .955.042 1.468.103a8.68 8.68 0 0 1 1.141.195v3.325a8.623 8.623 0 0 0-.653-.036 26.805 26.805 0 0 0-.733-.009c-.707 0-1.259.096-1.675.309a1.686 1.686 0 0 0-.679.622c-.258.42-.374.995-.374 1.752v1.297h3.919l-.386 2.103-.287 1.564h-3.246v8.245C19.396 23.238 24 18.179 24 12.044c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.628 3.874 10.35 9.101 11.647Z"/>) },
    "instagram.com" => { color: "#E4405F", path: %(<path d="M12 0C8.74 0 8.333.015 7.053.072 5.775.132 4.905.333 4.14.63c-.789.306-1.459.717-2.126 1.384S.935 3.35.63 4.14C.333 4.905.131 5.775.072 7.053.012 8.333 0 8.74 0 12s.015 3.667.072 4.947c.06 1.277.261 2.148.558 2.913.306.788.717 1.459 1.384 2.126.667.666 1.336 1.079 2.126 1.384.766.296 1.636.499 2.913.558C8.333 23.988 8.74 24 12 24s3.667-.015 4.947-.072c1.277-.06 2.148-.262 2.913-.558.788-.306 1.459-.718 2.126-1.384.666-.667 1.079-1.335 1.384-2.126.296-.765.499-1.636.558-2.913.06-1.28.072-1.687.072-4.947s-.015-3.667-.072-4.947c-.06-1.277-.262-2.149-.558-2.913-.306-.789-.718-1.459-1.384-2.126C21.319 1.347 20.651.935 19.86.63c-.765-.297-1.636-.499-2.913-.558C15.667.012 15.26 0 12 0Zm0 2.16c3.203 0 3.585.016 4.85.071 1.17.055 1.805.249 2.227.415.562.217.96.477 1.382.896.419.42.679.819.896 1.381.164.422.36 1.057.413 2.227.057 1.266.07 1.646.07 4.85s-.015 3.585-.074 4.85c-.061 1.17-.256 1.805-.421 2.227-.224.562-.479.96-.899 1.382-.419.419-.824.679-1.38.896-.42.164-1.065.36-2.235.413-1.274.057-1.649.07-4.859.07-3.211 0-3.586-.015-4.859-.074-1.171-.061-1.816-.256-2.236-.421-.569-.224-.96-.479-1.379-.899-.421-.419-.69-.824-.9-1.38-.165-.42-.359-1.065-.42-2.235-.045-1.26-.061-1.649-.061-4.844 0-3.196.016-3.586.061-4.861.061-1.17.255-1.814.42-2.234.21-.57.479-.96.9-1.381.419-.419.81-.689 1.379-.898.42-.166 1.051-.361 2.221-.421 1.275-.045 1.65-.06 4.859-.06Zm0 3.678a6.162 6.162 0 1 0 0 12.324 6.162 6.162 0 0 0 0-12.324ZM12 16a4 4 0 1 1 0-8 4 4 0 0 1 0 8Zm7.846-10.405a1.44 1.44 0 1 1-2.88 0 1.44 1.44 0 0 1 2.88 0Z"/>) },
    "youtube.com" => { color: "#FF0000", path: %(<path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814ZM9.545 15.568V8.432L15.818 12l-6.273 3.568Z"/>) },
    "youtu.be" => { color: "#FF0000", path: %(<path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814ZM9.545 15.568V8.432L15.818 12l-6.273 3.568Z"/>) },
    "whatsapp.com" => { color: "#25D366", path: %(<path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 0 1-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 0 1-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 0 1 2.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0 0 12.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 0 0 5.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 0 0-3.48-8.413Z"/>) },
    "wa.me" => { color: "#25D366", path: %(<path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 0 1-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 0 1-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 0 1 2.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0 0 12.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 0 0 5.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 0 0-3.48-8.413Z"/>) }
  }.freeze

  # Host of an outbound URL without its "www." — "facebook.com". nil when the
  # value isn't an absolute URL, which is what an admin typing a bare domain
  # into the form leaves behind.
  def external_host(url)
    URI.parse(url.to_s).host&.downcase&.delete_prefix("www.")
  rescue URI::InvalidURIError
    nil
  end

  # The origin site's mark for an outbound link. Matches the host itself and any
  # subdomain of it ("web.facebook.com"), never a lookalike ("notfacebook.com"),
  # and falls back to a neutral globe for everything we don't have a glyph for.
  def external_site_mark(url, klass: "h-4 w-4")
    host = external_host(url) or return icon(:globe, klass: klass)
    mark = BRAND_MARKS.find { |domain, _| host == domain || host.end_with?(".#{domain}") }&.last
    return icon(:globe, klass: klass) unless mark

    tag.svg(mark[:path].html_safe, class: klass, viewBox: "0 0 24 24", fill: "currentColor",
      style: "color: #{mark[:color]}", "aria-hidden": true, xmlns: "http://www.w3.org/2000/svg")
  end

  # A property's average rating shown Airbnb-style — one decimal, locale-aware
  # (a comma in es/pt).
  def rating_display(property)
    number_with_precision(property.rating_cache, precision: 1, locale: I18n.locale)
  end

  def star_icon(klass: "h-4 w-4")
    tag.svg(%(<path d="M11.48 3.499a.562.562 0 0 1 1.04 0l2.125 5.111a.563.563 0 0 0 .475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 0 0-.182.557l1.285 5.385a.562.562 0 0 1-.84.61l-4.725-2.885a.562.562 0 0 0-.586 0L6.982 20.54a.562.562 0 0 1-.84-.61l1.285-5.386a.562.562 0 0 0-.182-.557l-4.204-3.602a.563.563 0 0 1 .321-.988l5.518-.442a.563.563 0 0 0 .475-.345L11.48 3.5Z"/>).html_safe,
      class: klass, viewBox: "0 0 24 24", fill: "currentColor", "aria-hidden": true, xmlns: "http://www.w3.org/2000/svg")
  end
end
