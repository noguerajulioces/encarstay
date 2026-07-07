require "test_helper"

class PublicBookingFlowTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @property = properties(:lago)
    @check_in = Date.current + 30
    @check_out = @check_in + 3
  end

  test "home lists the active properties" do
    get root_path
    assert_response :success
    assert_select "h1", /escapada/i
    assert_match @property.name, response.body
  end

  test "search shows properties available for the dates" do
    get search_path(search: { check_in: @check_in, check_out: @check_out, guests: 2 })
    assert_response :success
    assert_match @property.name, response.body
  end

  test "property page renders with a quote when dates are given" do
    get property_path(@property, check_in: @check_in, check_out: @check_out)
    assert_response :success
    assert_select "h1", @property.name
    assert_select "turbo-frame#quote", 1
    assert_match "Reservar", response.body
  end

  test "checkout renders the request form" do
    get new_booking_path(property_slug: @property.slug, check_in: @check_in, check_out: @check_out, guests: 2)
    assert_response :success
    assert_select "form"
  end

  test "submitting a request creates a pending booking and emails guest + admin" do
    assert_enqueued_emails 2 do
      assert_difference "Booking.count", 1 do
        post bookings_path, params: { booking: {
          property_id: @property.id, check_in: @check_in, check_out: @check_out,
          guests_count: 2, guest_name: "Ana Díaz", guest_email: "ana@example.com", guest_phone: "0981"
        } }
      end
    end

    booking = Booking.last
    assert booking.pending?
    assert_redirected_to booking_path(booking.code)
    follow_redirect!
    assert_match booking.code, response.body
    assert_match "Recibimos tu solicitud", response.body
  end

  test "the honeypot silently drops spam without creating a booking" do
    assert_no_difference "Booking.count" do
      post bookings_path, params: { company: "spammer", booking: {
        property_id: @property.id, check_in: @check_in, check_out: @check_out,
        guests_count: 2, guest_name: "Bot", guest_email: "bot@example.com"
      } }
    end
    assert_redirected_to root_path
  end

  test "double booking is rejected and re-renders the form" do
    @property.book!(check_in: @check_in, check_out: @check_out, guests_count: 2,
      guest_name: "Ana", guest_email: "ana@example.com")

    assert_no_difference "Booking.count" do
      post bookings_path, params: { booking: {
        property_id: @property.id, check_in: @check_in, check_out: @check_out,
        guests_count: 2, guest_name: "Bob", guest_email: "bob@example.com"
      } }
    end
    assert_response :unprocessable_entity
  end
end
