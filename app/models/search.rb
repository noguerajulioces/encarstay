# Parses the public search form (dates + guests) and returns the active properties
# available for the requested stay. A plain filter object — no table behind it.
class Search
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :check_in, :date
  attribute :check_out, :date
  attribute :guests, :integer, default: 2

  def performed?
    check_in.present? || check_out.present?
  end

  def valid_range?
    check_in.present? && check_out.present? && check_out > check_in
  end

  def nights
    valid_range? ? (check_out - check_in).to_i : 0
  end

  # N+1 across availability is fine here: this catalog holds a handful of properties.
  def results
    return [] unless valid_range?
    Property.active.accommodating(guests).alphabetically.select { |property| property.available?(check_in, check_out) }
  end

  # The left-hand list for the search+map page: availability-filtered results when
  # a valid date range is given, otherwise the whole active catalogue so the map
  # is useful even before dates are picked.
  def list
    valid_range? ? results : Property.active.alphabetically
  end
end
