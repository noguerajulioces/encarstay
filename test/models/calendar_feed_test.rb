require "test_helper"

class CalendarFeedTest < ActiveSupport::TestCase
  setup do
    @property = properties(:lago)
  end

  test "publishes active bookings and blocks as busy events" do
    @property.book!(check_in: Date.new(2026, 8, 10), check_out: Date.new(2026, 8, 14),
      guests_count: 2, guest_name: "Ana Díaz", guest_email: "ana@example.com")
    @property.blocks.create!(starts_on: Date.new(2026, 9, 1), ends_on: Date.new(2026, 9, 3), reason: "Mantenimiento")

    ical = CalendarFeed.new(@property).to_ical
    events = Icalendar::Calendar.parse(ical).first.events

    assert_equal 2, events.size
    assert_equal [ Date.new(2026, 8, 10), Date.new(2026, 9, 1) ], events.map { |e| e.dtstart.to_date }.sort
  end

  test "never leaks guest data" do
    @property.book!(check_in: Date.new(2026, 8, 10), check_out: Date.new(2026, 8, 14),
      guests_count: 2, guest_name: "Ana Díaz", guest_email: "ana@example.com")

    ical = CalendarFeed.new(@property).to_ical
    assert_no_match "Ana Díaz", ical
    assert_no_match "ana@example.com", ical
    assert_match "Reservado", ical
  end

  test "excludes cancelled bookings" do
    booking = @property.book!(check_in: Date.new(2026, 8, 10), check_out: Date.new(2026, 8, 14),
      guests_count: 2, guest_name: "Ana", guest_email: "ana@example.com")
    booking.cancel!

    events = Icalendar::Calendar.parse(CalendarFeed.new(@property).to_ical).first.events
    assert_empty events
  end
end
