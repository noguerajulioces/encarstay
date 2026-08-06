require "test_helper"

class SearchTest < ActionDispatch::IntegrationTest
  test "the old search page moves permanently to the comparator" do
    get search_path
    assert_response :moved_permanently
    assert_includes response.headers["Location"], "/properties#comparador"
  end

  test "the redirect carries dates and guests over to the comparator" do
    check_in = Date.current + 30
    get search_path(search: { check_in: check_in.to_s, check_out: (check_in + 3).to_s, guests: 2 })

    assert_response :moved_permanently
    location = response.headers["Location"]
    assert_includes location, "search%5Bcheck_in%5D=#{check_in}"
    assert_includes location, "search%5Bcheck_out%5D=#{check_in + 3}"
    assert_includes location, "search%5Bguests%5D=2"
    assert_includes location, "#comparador"
  end
end
