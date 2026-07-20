require "test_helper"

class PwaTest < ActionDispatch::IntegrationTest
  test "layout advertises the web app manifest" do
    get root_path

    assert_response :success
    assert_select "link[rel=manifest][href='#{pwa_manifest_path(format: :json)}']"
    assert_select "meta[name=theme-color][content='#faf8f5']"
    assert_select "meta[name=apple-mobile-web-app-capable][content=yes]"
  end

  test "manifest contains installable app metadata and icons" do
    get pwa_manifest_path(format: :json)

    assert_response :success
    assert_equal "application/json", response.media_type

    manifest = JSON.parse(response.body)
    assert_equal "Encar Stays", manifest["name"]
    assert_equal "standalone", manifest["display"]
    assert_equal "/", manifest["start_url"]
    assert_equal %w[ 192x192 512x512 ], manifest["icons"].pluck("sizes")
  end

  test "service worker provides an offline fallback without caching pages" do
    get pwa_service_worker_path(format: :js)

    assert_response :success
    assert_includes %w[ application/javascript text/javascript ], response.media_type
    assert_includes response.body, 'caches.match("/offline.html")'
    assert_includes response.body, 'request.mode === "navigate"'
    assert_no_match(/cache\.put\(request.*navigate/m, response.body)
  end

  test "offline page is available" do
    get "/offline.html"

    assert_response :success
    assert_includes response.body.force_encoding(Encoding::UTF_8), "Estás sin conexión"
  end
end
