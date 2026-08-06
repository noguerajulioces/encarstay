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
      admin_property_path(@property), edit_admin_property_path(@property),
      admin_property_reviews_path(@property), new_admin_property_review_path(@property),
      admin_posts_path, new_admin_post_path, edit_admin_post_path(posts(:verano)),
      admin_subscribers_path, admin_campaigns_path, new_admin_campaign_path,
      admin_users_path, new_admin_user_path, edit_admin_user_path(users(:admin)) ].each do |path|
      get path
      assert_response :success, "Expected #{path} to render, got #{response.status}"
    end
  end

  test "admin can create, update, and remove another admin user" do
    sign_in

    assert_difference "User.count", 1 do
      post admin_users_path, params: { user: {
        name: "Ana Administradora", email: " ANA@EXAMPLE.COM ",
        password: "secret456", password_confirmation: "secret456"
      } }
    end

    user = User.find_by!(email: "ana@example.com")
    assert_redirected_to admin_users_path

    patch admin_user_path(user), params: { user: {
      name: "Ana Actualizada", email: "ana@example.com",
      password: "", password_confirmation: ""
    } }

    assert_redirected_to admin_users_path
    assert_equal "Ana Actualizada", user.reload.name
    assert user.authenticate("secret456"), "blank password fields should preserve the current password"

    assert_difference "User.count", -1 do
      delete admin_user_path(user)
    end
    assert_redirected_to admin_users_path
  end

  test "admin cannot remove their own user" do
    sign_in

    assert_no_difference "User.count" do
      delete admin_user_path(users(:admin))
    end

    assert_redirected_to admin_users_path
    assert_equal "No podés eliminar el usuario con el que estás conectado.", flash[:alert]
  end

  test "admin subscribers screen filters and exports CSV" do
    sign_in
    get admin_subscribers_path(status: "confirmed")
    assert_response :success

    get admin_subscribers_path(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match "email,status,source", response.body
  end

  test "admin can create a campaign, preview it, and launch delivery" do
    sign_in
    assert_difference "Campaign.count", 1 do
      post admin_campaigns_path, params: { campaign: { subject: "Ofertas de verano", body: "<div>Hola</div>" } }
    end
    campaign = Campaign.last
    assert_redirected_to admin_campaign_path(campaign)

    get admin_campaign_path(campaign)
    assert_response :success
    get edit_admin_campaign_path(campaign)
    assert_response :success

    assert_enqueued_with(job: CampaignDeliveryJob) do
      post deliver_admin_campaign_path(campaign)
    end
    assert campaign.reload.sending?
  end

  test "admin can invite past guests" do
    sign_in
    @property.book!(check_in: Date.current + 80, check_out: Date.current + 83, guests_count: 2,
      guest_name: "Vieja Clienta", guest_email: "old-guest@example.com", locale: "es")

    assert_enqueued_emails 1 do
      post admin_guest_invitations_path
    end
    assert_redirected_to admin_subscribers_path
  end

  test "admin can add a review and it refreshes the property rating" do
    sign_in
    bosque = properties(:bosque)
    assert_difference "bosque.reviews.count", 1 do
      post admin_property_reviews_path(bosque), params: { review: {
        reviewer_name: "Marta", reviewer_location: "Encarnación", rating: 5, body: "Genial", stayed_on: Date.current
      } }
    end
    assert_redirected_to admin_property_reviews_path(bosque)
    assert bosque.reload.rated?
    assert_in_delta 5.0, bosque.rating_cache, 0.001
  end

  test "the blog editor loads Trix CSS but public pages do not" do
    sign_in
    get new_admin_post_path
    assert_select "link[rel=stylesheet][href*=?]", "trix", { count: 1 }, "the blog editor should load Trix CSS"
    assert_select "trix-editor", 3, "the blog editor should render one Trix editor per locale (es/en/pt)"

    get posts_path
    assert_select "link[rel=stylesheet][href*=?]", "trix", false, "public pages must not load the Trix editor CSS"
  end

  test "creating a blog post generates a slug and redirects to edit" do
    sign_in
    assert_difference "Post.count", 1 do
      post admin_posts_path, params: { post: {
        title_es: "Nuevo artículo de prueba", body_es: "<div>Contenido</div>", published: "1"
      } }
    end
    assert_redirected_to edit_admin_post_path(Post.last)
    assert_equal "nuevo-articulo-de-prueba", Post.last.slug
    assert Post.last.published?
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

  test "admin can change a property's nightly price and cleaning fee" do
    sign_in

    patch admin_property_path(@property), params: { property: {
      name: @property.name, base_price: "4200", cleaning_fee: "700"
    } }

    assert_redirected_to admin_property_path(@property)
    @property.reload
    assert_equal 420_000, @property.base_price_cents
    assert_equal 70_000, @property.cleaning_fee_cents
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
