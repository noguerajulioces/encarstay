require "test_helper"

class PlausibleProxyTest < ActionDispatch::IntegrationTest
  test "the proxy is inert while PLAUSIBLE_BACKEND_URL is unset" do
    get "/plausible/js/script.outbound-links.js"
    assert_response :not_found

    post "/plausible/api/event", params: { n: "pageview" }.to_json, headers: { "Content-Type" => "application/json" }
    assert_response :not_found
  end

  test "only known script variants are proxied" do
    with_backend do
      get "/plausible/js/script.evil-variant.js"
      assert_response :not_found
    end
  end

  test "an unreachable backend answers 502 without breaking the page" do
    with_backend do
      get "/plausible/js/script.outbound-links.js"
      assert_response :bad_gateway
    end
  end

  test "the tracking tag renders only when PLAUSIBLE_DOMAIN is set" do
    get root_path
    assert_no_match "plausible", response.body

    ENV["PLAUSIBLE_DOMAIN"] = "example.org"
    get root_path
    assert_match %r{data-domain="example.org"}, response.body
    assert_match %r{src="/plausible/js/script\.outbound-links\.js"}, response.body
  ensure
    ENV.delete("PLAUSIBLE_DOMAIN")
  end

  private
    # Points the proxy at a port nothing listens on — enough to exercise the
    # routing, the whitelist, and the fail-soft path without a real server.
    def with_backend
      ENV["PLAUSIBLE_BACKEND_URL"] = "http://127.0.0.1:9"
      yield
    ensure
      ENV.delete("PLAUSIBLE_BACKEND_URL")
    end
end
