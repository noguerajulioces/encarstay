require "test_helper"

class SeoTest < ActionDispatch::IntegrationTest
  setup { @property = properties(:lago) }

  test "sitemap lists home and property urls as xml" do
    get sitemap_path
    assert_response :success
    assert_equal "application/xml", response.media_type
    assert_match "<urlset", response.body
    assert_match @property.slug, response.body
  end

  test "home exposes canonical, description and organization structured data" do
    get root_path
    assert_select "link[rel=canonical]"
    assert_select "meta[name=description]"
    assert_select "meta[property='og:title']"
    assert_match '"@type":"Organization"', response.body
  end

  test "property page exposes Product structured data and og:image type" do
    get property_path(@property)
    assert_select "meta[property='og:type'][content=product]"
    assert_match '"@type":"Product"', response.body
    assert_match '"priceCurrency":"PYG"', response.body
    assert_match '"@type":"BreadcrumbList"', response.body
  end

  test "the canonical drops query params" do
    get property_path(@property, check_in: "2026-08-10", check_out: "2026-08-14")
    assert_select "link[rel=canonical]" do |links|
      assert_no_match(/check_in/, links.first["href"])
    end
  end

  test "blog post exposes BlogPosting structured data and article og:type" do
    get post_path(posts(:verano))
    assert_response :success
    assert_select "meta[property='og:type'][content=article]"
    assert_match '"@type":"BlogPosting"', response.body
    assert_match '"@type":"BreadcrumbList"', response.body
  end

  test "sitemap lists published blog posts but not drafts" do
    get sitemap_path
    assert_match posts(:verano).slug, response.body
    assert_no_match(/#{posts(:borrador).slug}/, response.body)
  end
end
