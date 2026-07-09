require "test_helper"

class SearchTest < ActionDispatch::IntegrationTest
  test "without a date range the search page lists the active stays" do
    get search_path
    assert_response :success
    assert_match properties(:lago).name, response.body
  end

  test "with a date range the search page lists available stays" do
    check_in = Date.current + 30
    get search_path(search: { check_in: check_in.to_s, check_out: (check_in + 3).to_s, guests: 2 })
    assert_response :success
    assert_match properties(:lago).name, response.body
  end
end
