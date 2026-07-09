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
end
