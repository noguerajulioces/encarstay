require "test_helper"

class PropertyTest < ActiveSupport::TestCase
  setup do
    @property = properties(:lago)
    @in  = Date.new(2026, 8, 10)
    @out = Date.new(2026, 8, 14)
  end

  test "available when nothing overlaps the range" do
    assert @property.available?(@in, @out)
  end

  test "generates a slug and a calendar token on create" do
    property = Property.create!(name: "Casa Nueva", currency: "PYG")
    assert_equal "casa-nueva", property.slug
    assert property.calendar_token.present?
  end

  # --- The golden rule: bookings ---

  test "not available when an active booking overlaps" do
    book @in, @out
    assert_not @property.available?(Date.new(2026, 8, 12), Date.new(2026, 8, 13))
  end

  test "check-out day is free: adjacent stays do not collide" do
    book @in, @out # occupies nights 10,11,12,13; departs the 14th
    assert @property.available?(@out, Date.new(2026, 8, 16))
    assert @property.available?(Date.new(2026, 8, 8), @in)
  end

  test "cancelled bookings free the dates" do
    booking = book @in, @out
    assert_not @property.available?(@in, @out)

    booking.cancel!
    assert @property.available?(@in, @out)
  end

  test "completed and cancelled bookings do not occupy" do
    assert_empty Booking.occupying.where(status: %w[ completed cancelled ])
  end

  # --- The golden rule: manual blocks ---

  test "not available when a manual block overlaps" do
    @property.blocks.create!(starts_on: @in, ends_on: @out, reason: "Mantenimiento")
    assert_not @property.available?(Date.new(2026, 8, 11), Date.new(2026, 8, 12))
  end

  # --- The golden rule: imported external events (Airbnb) ---

  test "not available when an imported external event overlaps" do
    calendar_sources(:lago_airbnb).external_events.create!(
      uid: "abnb-1", starts_on: @in, ends_on: @out, summary: "Reserved"
    )
    assert_not @property.available?(Date.new(2026, 8, 13), Date.new(2026, 8, 15))
  end

  test "external events on another property do not affect availability" do
    calendar_sources(:lago_airbnb).external_events.create!(
      uid: "abnb-2", starts_on: @in, ends_on: @out
    )
    assert properties(:bosque).available?(@in, @out)
  end

  # --- Race protection ---

  test "book! rejects a stay that overlaps an existing one" do
    book @in, @out

    assert_raises ActiveRecord::RecordInvalid do
      @property.book!(check_in: Date.new(2026, 8, 11), check_out: Date.new(2026, 8, 13),
        guest_name: "Bob", guest_email: "bob@example.com")
    end
  end

  private
    def book(check_in, check_out)
      @property.book!(check_in: check_in, check_out: check_out,
        guests_count: 2, guest_name: "Ana", guest_email: "ana@example.com")
    end
end
