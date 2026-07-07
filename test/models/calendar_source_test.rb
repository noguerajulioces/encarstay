require "test_helper"

class CalendarSourceTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @source = calendar_sources(:lago_airbnb)
    @property = @source.property
  end

  test "imports events from the feed, upserting by uid" do
    @source.import_from(ical([ [ "e1", "20260810", "20260814" ], [ "e2", "20260901", "20260903" ] ]))

    assert_equal 2, @source.external_events.count
    event = @source.external_events.find_by(uid: "e1")
    assert_equal Date.new(2026, 8, 10), event.starts_on
    assert_equal Date.new(2026, 8, 14), event.ends_on
  end

  test "updates an event whose dates changed" do
    @source.import_from(ical([ [ "e1", "20260810", "20260814" ] ]))
    @source.import_from(ical([ [ "e1", "20260811", "20260815" ] ]))

    assert_equal 1, @source.external_events.count
    assert_equal Date.new(2026, 8, 11), @source.external_events.first.starts_on
  end

  test "deletes events that vanished from the feed (upstream cancellation)" do
    @source.import_from(ical([ [ "e1", "20260810", "20260814" ], [ "e2", "20260901", "20260903" ] ]))
    @source.import_from(ical([ [ "e1", "20260810", "20260814" ] ]))

    assert_equal [ "e1" ], @source.external_events.pluck(:uid)
  end

  test "an empty feed clears all imported events" do
    @source.import_from(ical([ [ "e1", "20260810", "20260814" ] ]))
    @source.import_from(ical([]))
    assert_equal 0, @source.external_events.count
  end

  test "alerts on a collision with a direct booking" do
    @property.book!(check_in: Date.new(2026, 8, 10), check_out: Date.new(2026, 8, 14),
      guests_count: 2, guest_name: "Ana", guest_email: "ana@example.com")

    assert_enqueued_emails 1 do
      @source.import_from(ical([ [ "e1", "20260812", "20260816" ] ]))
    end
  end

  test "does not alert when the imported event does not overlap a booking" do
    @property.book!(check_in: Date.new(2026, 8, 10), check_out: Date.new(2026, 8, 14),
      guests_count: 2, guest_name: "Ana", guest_email: "ana@example.com")

    assert_no_enqueued_emails do
      @source.import_from(ical([ [ "e1", "20260814", "20260816" ] ]))
    end
  end

  private
    def ical(events)
      lines = [ "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Test//EN" ]
      events.each do |uid, starts, ends|
        lines += [ "BEGIN:VEVENT", "UID:#{uid}", "DTSTART;VALUE=DATE:#{starts}", "DTEND;VALUE=DATE:#{ends}", "SUMMARY:Reserved", "END:VEVENT" ]
      end
      lines << "END:VCALENDAR"
      lines.join("\r\n")
    end
end
