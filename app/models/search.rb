# Parses the public dates+guests form that feeds the /properties comparator.
# A plain form object — no table behind it.
class Search
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :check_in, :date
  attribute :check_out, :date
  attribute :guests, :integer, default: 2

  def valid_range?
    check_in.present? && check_out.present? && check_out > check_in
  end

  def nights
    valid_range? ? (check_out - check_in).to_i : 0
  end
end
