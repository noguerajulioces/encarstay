require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  setup { @property = properties(:bosque) } # starts with no reviews

  test "requires a reviewer name" do
    review = @property.reviews.build(rating: 5)
    assert_not review.valid?
    assert_includes review.errors[:reviewer_name], I18n.t("errors.messages.blank")
  end

  test "rating must be an integer within 1..5" do
    assert @property.reviews.build(reviewer_name: "Ana", rating: 5).valid?
    assert_not @property.reviews.build(reviewer_name: "Ana", rating: 0).valid?
    assert_not @property.reviews.build(reviewer_name: "Ana", rating: 6).valid?
    assert_not @property.reviews.build(reviewer_name: "Ana", rating: 4.5).valid?
  end

  test "creating a review refreshes the property's cached aggregates" do
    assert_equal 0, @property.reviews_count

    @property.reviews.create!(reviewer_name: "Ana", rating: 4)
    @property.reviews.create!(reviewer_name: "Beto", rating: 5)
    @property.reload

    assert_equal 2, @property.reviews_count
    assert_in_delta 4.5, @property.rating_cache, 0.001
    assert @property.rated?
  end

  test "destroying the last review resets the aggregates" do
    review = @property.reviews.create!(reviewer_name: "Ana", rating: 5)
    @property.reload
    assert_equal 1, @property.reviews_count

    review.destroy
    @property.reload

    assert_equal 0, @property.reviews_count
    assert_nil @property.rating_cache
    assert_not @property.rated?
  end

  test "guest_favorite? needs a near-perfect average and enough reviews" do
    assert properties(:lago).guest_favorite? # fixture: 5 × 5★
    assert_not @property.guest_favorite?      # no reviews
  end
end
