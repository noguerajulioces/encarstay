require "test_helper"

class SearchMapTest < ActionDispatch::IntegrationTest
  test "the search page renders the map with data even without a date range" do
    get search_path
    assert_response :success
    assert_select "[data-controller='search-map']"
    assert_select "[data-search-map-properties-value]"
    assert_select "[data-search-map-attractions-value]"
    assert_select "[data-search-map-events-value]"
    assert_select "[data-search-map-target='map']"
  end

  test "the search page still renders with a date range" do
    get search_path(search: { check_in: Date.current.to_s, check_out: (Date.current + 3).to_s, guests: 2 })
    assert_response :success
    assert_select "[data-controller='search-map']"
  end

  test "geolocated properties are serialized as map markers" do
    get search_path
    attr = css_select("[data-search-map-properties-value]").first["data-search-map-properties-value"]
    markers = JSON.parse(attr)
    assert markers.any? { |m| m["name"] == properties(:bosque).name }, "expected the geolocated property in the marker payload"
    marker = markers.find { |m| m["name"] == properties(:bosque).name }
    assert marker["lat"].is_a?(Numeric)
    assert marker["lng"].is_a?(Numeric)
  end
end
