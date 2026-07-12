require "test_helper"

class PhotoTest < ActiveSupport::TestCase
  test "declares preprocessed WebP variants for every public photo surface" do
    variants = Photo.attachment_reflections.fetch("image").named_variants

    assert_equal %i[ card_small card preview gallery ], variants.keys
    variants.each_value do |variant|
      assert variant.preprocessed?(Photo.new)
      assert_equal :webp, variant.transformations.fetch(:format)
    end
  end
end
