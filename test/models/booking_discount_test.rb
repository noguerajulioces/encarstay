require "test_helper"

class BookingDiscountTest < ActiveSupport::TestCase
  setup do
    @property = properties(:lago)
    @check_in = Date.current + 40
    @check_out = @check_in + 3
    @subscriber = subscribers(:confirmed) # discount_code ENCAR-ABC123, unredeemed
  end

  def build_booking(code, check_in: @check_in, check_out: @check_out)
    @property.bookings.build(check_in:, check_out:, guests_count: 2,
      guest_name: "Ana", guest_email: "ana@example.com", applied_discount_code: code)
  end

  test "a valid welcome code applies 5% off the lodging subtotal" do
    booking = build_booking("ENCAR-ABC123")
    assert booking.valid?

    expected = (booking.subtotal_cents * 0.05).round
    assert_operator expected, :>, 0
    assert_equal expected, booking.discount_cents
    assert_equal booking.subtotal_cents + booking.cleaning_fee_cents - expected, booking.total_cents
  end

  test "the code is normalized to uppercase and trimmed" do
    booking = build_booking(" encar-abc123 ")
    assert booking.valid?
    assert_equal "ENCAR-ABC123", booking.applied_discount_code
    assert_operator booking.discount_cents, :>, 0
  end

  test "an unknown code is rejected" do
    booking = build_booking("ENCAR-NOPE99")
    assert_not booking.valid?
    assert_includes booking.errors.attribute_names, :applied_discount_code
  end

  test "a code from a pending (unconfirmed) subscriber is rejected" do
    subscribers(:pending).update_column(:discount_code, "ENCAR-PEND01")
    booking = build_booking("ENCAR-PEND01")
    assert_not booking.valid?
    assert_includes booking.errors.attribute_names, :applied_discount_code
  end

  test "no code means no discount and the full total" do
    booking = build_booking(nil)
    assert booking.valid?
    assert_equal 0, booking.discount_cents
    assert_equal booking.subtotal_cents + booking.cleaning_fee_cents, booking.total_cents
  end

  test "confirming a booking burns the code so it can't be reused" do
    booking = @property.book!(check_in: @check_in, check_out: @check_out, guests_count: 2,
      guest_name: "Ana", guest_email: "ana@example.com", applied_discount_code: "ENCAR-ABC123")
    assert_operator booking.discount_cents, :>, 0

    booking.confirm!
    assert @subscriber.reload.discount_redeemed_at.present?

    # A fresh booking (different dates) with the now-redeemed code is rejected.
    second = build_booking("ENCAR-ABC123", check_in: @check_in + 10, check_out: @check_in + 13)
    assert_not second.valid?
    assert_includes second.errors.attribute_names, :applied_discount_code
  end
end
