require "test_helper"

class AmenityTest < ActiveSupport::TestCase
  test "key must be present and unique" do
    assert_not Amenity.new.valid?
    assert_not Amenity.new(key: "wifi").valid? # already in fixtures
  end

  test "label is translated from the amenities i18n namespace" do
    assert_equal I18n.t("amenities.wifi"), amenities(:wifi).label
  end

  test "label falls back to a humanised key when the locale lacks it" do
    assert_equal "Foo bar", Amenity.new(key: "foo_bar").label
  end

  test "property has amenities through the join table" do
    assert_includes properties(:lago).amenities, amenities(:wifi)
    assert_includes properties(:lago).amenities, amenities(:pool)
    assert_not_includes properties(:lago).amenities, amenities(:tv)
  end
end
