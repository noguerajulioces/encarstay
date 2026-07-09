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

  # --- Coordinates & distance ---

  test "coordinates? is false without both lat and lng" do
    @property.latitude = nil
    @property.longitude = nil
    assert_not @property.coordinates?
    @property.latitude = -27.33
    assert_not @property.coordinates?, "needs both latitude and longitude"
    @property.longitude = -55.86
    assert @property.coordinates?
  end

  test "distance_km_to returns nil when the property has no coordinates" do
    @property.latitude = nil
    @property.longitude = nil
    assert_nil @property.distance_km_to(-27.33, -55.86)
  end

  test "distance_km_to returns nil when the target point is blank" do
    @property.update!(latitude: -27.33, longitude: -55.86)
    assert_nil @property.distance_km_to(nil, -55.86)
    assert_nil @property.distance_km_to(-27.33, nil)
  end

  test "distance to the same point is zero" do
    @property.update!(latitude: -27.33, longitude: -55.86)
    assert_in_delta 0.0, @property.distance_km_to(-27.33, -55.86), 0.001
  end

  test "one degree of latitude is about 111 km" do
    @property.update!(latitude: 0, longitude: 0)
    assert_in_delta 111.19, @property.distance_km_to(1, 0), 0.5
  end

  test "distance matches a known Encarnación landmark separation" do
    # Costanera ≈ (-27.336, -55.872), Playa San José ≈ (-27.325, -55.865): ~1.4 km apart.
    @property.update!(latitude: -27.336, longitude: -55.872)
    assert_in_delta 1.4, @property.distance_km_to(-27.325, -55.865), 0.3
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
