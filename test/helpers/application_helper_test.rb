require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "external_host strips www and normalises case" do
    assert_equal "facebook.com", external_host("https://WWW.Facebook.com/events/123")
  end

  test "external_host is nil without an absolute URL" do
    assert_nil external_host("facebook.com/events/123")
    assert_nil external_host("")
    assert_nil external_host(nil)
  end

  test "external_site_mark uses the brand colour, subdomains included" do
    assert_includes external_site_mark("https://facebook.com/events/1"), "#1877F2"
    assert_includes external_site_mark("https://web.facebook.com/events/1"), "#1877F2"
  end

  test "external_site_mark ignores a lookalike domain" do
    assert_not_includes external_site_mark("https://notfacebook.com/events/1"), "#1877F2"
  end

  test "external_site_mark falls back to a neutral glyph" do
    mark = external_site_mark("https://municipalidad.gov.py/agenda")

    assert_includes mark, "<svg"
    assert_not_includes mark, "color: #"
  end
end
