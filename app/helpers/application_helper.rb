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
    "#{count} #{count == 1 ? 'noche' : 'noches'}"
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
      "completed" => "bg-stone-200 text-stone-700",
      "cancelled" => "bg-rose-100 text-rose-700"
    }.fetch(status.to_s, "bg-stone-100 text-stone-600")
  end

  def status_label(status)
    { "pending" => "Pendiente", "confirmed" => "Confirmada",
      "completed" => "Completada", "cancelled" => "Cancelada" }.fetch(status.to_s, status.to_s)
  end
end
