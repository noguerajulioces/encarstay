require "test_helper"

class QuoteTest < ActiveSupport::TestCase
  setup do
    @property = properties(:lago) # base 350000, limpieza 50000
  end

  test "charges base price per night plus the cleaning fee" do
    quote = @property.quote(Date.new(2026, 8, 10), Date.new(2026, 8, 14))
    assert_equal 4, quote.nights
    assert_equal 4 * 350_000, quote.subtotal_cents
    assert_equal 50_000, quote.cleaning_fee_cents
    assert_equal 4 * 350_000 + 50_000, quote.total_cents
    assert_equal "PYG", quote.currency
  end

  test "applies the seasonal rate only to the nights it covers" do
    @property.seasonal_rates.create!(name: "Alta", starts_on: Date.new(2026, 8, 10),
      ends_on: Date.new(2026, 8, 12), price_per_night_cents: 500_000)

    # Nights 10, 11, 12 at 500k; night 13 falls back to base 350k.
    quote = @property.quote(Date.new(2026, 8, 10), Date.new(2026, 8, 14))
    assert_equal 3 * 500_000 + 350_000, quote.subtotal_cents
  end

  test "deposit is half the total rounded up" do
    quote = @property.quote(Date.new(2026, 8, 10), Date.new(2026, 8, 13)) # 3*350k + 50k = 1_100_000
    assert_equal 1_100_000, quote.total_cents
    assert_equal 550_000, quote.deposit_cents
  end

  test "an invalid range yields a zero quote" do
    quote = @property.quote(Date.new(2026, 8, 14), Date.new(2026, 8, 10))
    assert_equal 0, quote.nights
    assert_equal 0, quote.total_cents
  end
end
