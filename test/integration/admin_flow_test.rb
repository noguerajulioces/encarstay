require "test_helper"

class AdminFlowTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @property = properties(:lago)
    @check_in = Date.current + 40
    @check_out = @check_in + 3
  end

  test "the admin area requires signing in" do
    get admin_root_path
    assert_redirected_to new_admin_session_path
  end

  test "every admin page renders" do
    sign_in
    booking = create_booking
    @property.seasonal_rates.create!(name: "Alta", starts_on: Date.new(2026, 12, 15), ends_on: Date.new(2027, 2, 28), price_per_night_cents: 60_000_000)
    @property.blocks.create!(starts_on: Date.current + 2, ends_on: Date.current + 4, reason: "Mantenimiento")

    [ admin_root_path, admin_calendar_path, admin_bookings_path, new_admin_booking_path,
      admin_booking_path(booking), admin_properties_path, new_admin_property_path,
      admin_property_path(@property), edit_admin_property_path(@property) ].each do |path|
      get path
      assert_response :success, "Expected #{path} to render, got #{response.status}"
    end
  end

  test "signing in reaches the dashboard, bad credentials do not" do
    post admin_session_path, params: { email: "admin@example.com", password: "wrong" }
    assert_response :unprocessable_entity

    sign_in
    get admin_root_path
    assert_response :success
    assert_select "h1", /Hola/
  end

  test "confirming a booking marks it confirmed and emails the guest" do
    sign_in
    booking = create_booking

    assert_enqueued_emails 1 do
      post admin_booking_confirmation_path(booking)
    end
    assert booking.reload.confirmed?
  end

  test "cancelling a booking frees the dates" do
    sign_in
    booking = create_booking
    post admin_booking_cancellation_path(booking)
    assert booking.reload.cancelled?
    assert @property.available?(@check_in, @check_out)
  end

  test "creating a manual booking" do
    sign_in
    assert_difference "Booking.count", 1 do
      post admin_bookings_path, params: { booking: {
        property_id: @property.id, check_in: @check_in, check_out: @check_out,
        guests_count: 2, guest_name: "Teléfono Juan", guest_email: "juan@example.com"
      } }
    end
    assert Booking.last.manual?
  end

  test "managing seasonal rates and calendar sources on a property" do
    sign_in

    assert_difference "@property.seasonal_rates.count", 1 do
      post admin_property_seasonal_rates_path(@property), params: {
        name: "Alta", starts_on: "2026-12-15", ends_on: "2027-02-28", price_per_night: "600000", min_nights: 3
      }
    end

    assert_difference "@property.calendar_sources.count", 1 do
      post admin_property_calendar_sources_path(@property), params: { name: "Airbnb", ical_url: "https://airbnb.com/x.ics" }
    end
  end

  test "triggering a manual sync enqueues an import job" do
    sign_in
    source = calendar_sources(:lago_airbnb)
    assert_enqueued_with job: ImportCalendarJob do
      post admin_property_calendar_source_sync_path(@property, source)
    end
  end

  test "blocking and unblocking dates" do
    sign_in
    assert_difference "Block.count", 1 do
      post admin_blocks_path, params: { property_id: @property.id, starts_on: @check_in, ends_on: @check_out, reason: "Uso personal" }
    end
    assert_not @property.available?(@check_in, @check_out)

    block = Block.last
    assert_difference "Block.count", -1 do
      delete admin_block_path(block)
    end
  end

  test "the public iCal feed serves calendar data for a valid token" do
    create_booking
    get calendar_feed_path(calendar_token: @property.calendar_token, slug: @property.slug)
    assert_response :success
    assert_equal "text/calendar", response.media_type
    assert_match "BEGIN:VCALENDAR", response.body
  end

  test "the iCal feed 404s for an unknown token" do
    get calendar_feed_path(calendar_token: "nope", slug: "x")
    assert_response :not_found
  end

  private
    def sign_in
      post admin_session_path, params: { email: "admin@example.com", password: "secret123" }
    end

    def create_booking
      @property.book!(check_in: @check_in, check_out: @check_out, guests_count: 2,
        guest_name: "Ana", guest_email: "ana@example.com")
    end
end
