require "test_helper"

class BookingTest < ActiveSupport::TestCase
  setup do
    @property = properties(:lago)
  end

  test "generates a unique public code and defaults to a pending direct booking" do
    booking = create_booking
    assert_match(/\ARES-[A-Z0-9]{4}\z/, booking.code)
    assert booking.pending?
    assert booking.direct?
  end

  test "computes nights from the stay" do
    booking = create_booking(check_in: Date.new(2026, 9, 1), check_out: Date.new(2026, 9, 5))
    assert_equal 4, booking.nights
  end

  test "confirm! moves to confirmed and stamps the time" do
    booking = create_booking
    booking.confirm!
    assert booking.confirmed?
    assert_not_nil booking.confirmed_at
  end

  test "cancel! moves to cancelled and stamps the time" do
    booking = create_booking
    booking.cancel!
    assert booking.cancelled?
    assert_not_nil booking.cancelled_at
  end

  test "requires check-out to be after check-in" do
    booking = @property.bookings.build(check_in: Date.new(2026, 9, 5), check_out: Date.new(2026, 9, 5),
      guest_name: "Ana", guest_email: "ana@example.com")
    assert_not booking.valid?
    assert_includes booking.errors[:check_out], "debe ser posterior al check-in"
  end

  test "requires guest name and email" do
    booking = @property.bookings.build(check_in: Date.new(2026, 9, 1), check_out: Date.new(2026, 9, 3))
    assert_not booking.valid?
    assert_includes booking.errors.attribute_names, :guest_name
    assert_includes booking.errors.attribute_names, :guest_email
  end

  test "overlapping scope respects half-open ranges" do
    booking = create_booking(check_in: Date.new(2026, 9, 10), check_out: Date.new(2026, 9, 14))
    assert_includes Booking.overlapping(Date.new(2026, 9, 13), Date.new(2026, 9, 20)), booking
    assert_not_includes Booking.overlapping(Date.new(2026, 9, 14), Date.new(2026, 9, 20)), booking
  end

  test "freezes the priced amounts on create" do
    booking = create_booking(check_in: Date.new(2026, 9, 1), check_out: Date.new(2026, 9, 4))
    assert_equal 3 * 350_000, booking.subtotal_cents
    assert_equal 50_000, booking.cleaning_fee_cents
    assert_equal 3 * 350_000 + 50_000, booking.total_cents
    assert_equal 550_000, booking.deposit_cents
    assert_equal "PYG", booking.currency
  end

  test "rejects a stay below the minimum nights" do
    booking = @property.bookings.build(check_in: Date.new(2026, 9, 1), check_out: Date.new(2026, 9, 2),
      guests_count: 2, guest_name: "Ana", guest_email: "ana@example.com")
    assert_not booking.valid?
    assert_includes booking.errors[:base], "La estadía mínima es de 2 noches"
  end

  test "rejects more guests than the property capacity" do
    booking = @property.bookings.build(check_in: Date.new(2026, 9, 1), check_out: Date.new(2026, 9, 3),
      guests_count: 99, guest_name: "Ana", guest_email: "ana@example.com")
    assert_not booking.valid?
    assert_includes booking.errors.attribute_names, :guests_count
  end

  private
    def create_booking(check_in: Date.new(2026, 9, 1), check_out: Date.new(2026, 9, 3))
      @property.book!(check_in: check_in, check_out: check_out,
        guests_count: 2, guest_name: "Ana", guest_email: "ana@example.com")
    end
end
