# Builds the outgoing .ics feed for a property — the one Airbnb imports.
# Publishes only occupied ranges (active bookings + manual blocks); never any
# guest data, just busy dates.
class CalendarFeed
  def initialize(property)
    @property = property
  end

  def to_ical
    calendar = Icalendar::Calendar.new
    calendar.prodid = "-//Reserva Directo//Reservas//ES"

    busy_periods.each do |uid, starts_on, ends_on, summary|
      calendar.event do |event|
        event.dtstart = Icalendar::Values::Date.new(starts_on)
        event.dtend   = Icalendar::Values::Date.new(ends_on)
        event.summary = summary
        event.uid     = uid
        event.transp  = "OPAQUE"
      end
    end

    calendar.publish
    calendar.to_ical
  end

  private
    def busy_periods
      bookings = @property.bookings.occupying.map do |booking|
        [ "booking-#{booking.id}@reservadirecto", booking.check_in, booking.check_out, "Reservado" ]
      end
      blocks = @property.blocks.map do |block|
        [ "block-#{block.id}@reservadirecto", block.starts_on, block.ends_on, block.reason.presence || "No disponible" ]
      end
      bookings + blocks
    end
end
