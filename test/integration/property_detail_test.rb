require "test_helper"

class PropertyDetailTest < ActionDispatch::IntegrationTest
  setup { @property = properties(:lago) }

  test "detail page renders amenities and reviews sections" do
    get property_path(@property)
    assert_response :success

    # Title untouched, booking hook intact.
    assert_select "h1", @property.name
    assert_select "turbo-frame#quote", 1

    # New sections.
    assert_match I18n.t("property.amenities_title"), response.body
    assert_match I18n.t("amenities.wifi"), response.body               # an amenity label
    assert_match "Todo impecable y muy bien ubicado.", response.body   # a review body
    assert_select "#evaluaciones"                                       # reviews section anchor
  end

  test "a listing without reviews shows the New label instead of a rating" do
    get property_path(properties(:bosque))
    assert_response :success
    assert_no_match(/#evaluaciones/, response.body)
  end

  test "cards expose the favorite toggle hook" do
    get root_path
    assert_response :success
    assert_select "button[data-controller='favorite'][data-favorite-slug-value=?]", @property.slug
  end

  test "property cards load one image and defer the rest of the carousel" do
    property = properties(:bosque)
    attach_photo(property, "first.png")
    attach_photo(property, "second.png")

    get search_path
    assert_response :success

    assert_select "[data-controller='card-carousel']", 1 do
      assert_select "img[data-card-carousel-target='image']", 2
      assert_select "img[data-card-carousel-target='image'][src*='/rails/active_storage/representations/proxy/']", 1
      assert_select "img[data-card-carousel-target='image']:not([src])[data-card-carousel-src-value*='/rails/active_storage/representations/proxy/']", 1
      assert_select "img[loading='eager'][fetchpriority='high']", 1
      assert_select "img[srcset]", 0
    end
  end

  test "proxy variants are WebP and publicly cacheable" do
    photo = attach_photo(@property, "cacheable.png")

    get rails_storage_proxy_path(photo.image.variant(:card_small))

    assert_response :success
    assert_equal "image/webp", response.media_type
    assert_includes response.headers.fetch("Cache-Control"), "public"
    assert_includes response.headers.fetch("Cache-Control"), "immutable"
  end

  private
    def attach_photo(property, filename)
      property.photos.create!(position: property.photos.count).tap do |photo|
        File.open(Rails.root.join("public/icon.png")) do |file|
          photo.image.attach(io: file, filename: filename, content_type: "image/png")
        end
      end
    end
end
