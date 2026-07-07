# Prices a stay for a property: each night is charged at its seasonal rate when one
# applies, otherwise at the property's base price. Plus a one-off cleaning fee.
# Used by the public quoter, the search results, and frozen into a Booking on create.
class Quote
  attr_reader :property, :check_in, :check_out

  def initialize(property, check_in, check_out)
    @property = property
    @check_in = check_in
    @check_out = check_out
  end

  def nights
    return 0 unless valid?
    (check_out - check_in).to_i
  end

  def subtotal_cents
    return 0 unless valid?
    (check_in...check_out).sum { |date| property.rate_for(date) }
  end

  def cleaning_fee_cents
    valid? ? property.cleaning_fee_cents : 0
  end

  def total_cents
    subtotal_cents + cleaning_fee_cents
  end

  # Half of the total, rounded up to the currency's minor unit — the deposit
  # (seña) the guest pays to hold the booking.
  def deposit_cents
    (total_cents / 2.0).ceil
  end

  def currency
    property.currency
  end

  def valid?
    check_in.present? && check_out.present? && check_out > check_in
  end
end
