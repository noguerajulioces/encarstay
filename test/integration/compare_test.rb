require "test_helper"

class CompareTest < ActionDispatch::IntegrationTest
  test "the comparator lists every active stay without availability chips until dates are picked" do
    get properties_path
    assert_response :success
    assert_select "#comparador article", Property.active.count
    assert_match properties(:lago).name, response.body
    assert_match properties(:bosque).name, response.body
    assert_no_match I18n.t("compare.available"), response.body

    # Distancias por calle: se muestran cuando están cargadas y se omiten si no.
    assert_match I18n.t("compare.distance_center", distance: "1,2 km"), response.body
    assert_match I18n.t("compare.distance_costanera", distance: "2,3 km"), response.body
  end

  test "with dates the comparator marks occupied stays and keeps the free ones bookable" do
    check_in = Date.current + 30
    properties(:lago).blocks.create!(starts_on: check_in, ends_on: check_in + 2)

    get properties_path(search: { check_in: check_in.to_s, check_out: (check_in + 2).to_s, guests: 2 })
    assert_response :success
    assert_match I18n.t("compare.unavailable"), response.body
    assert_match I18n.t("compare.available"), response.body
  end

  test "a group above a stay's capacity sees its limit instead of an availability verdict" do
    check_in = Date.current + 30
    get properties_path(search: { check_in: check_in.to_s, check_out: (check_in + 2).to_s, guests: 3 })
    assert_response :success
    assert_match I18n.t("compare.fits_up_to", count: properties(:bosque).capacity), response.body
    assert_match I18n.t("compare.available"), response.body
  end
end
