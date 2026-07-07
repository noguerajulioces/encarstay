# Shared date-range occupancy for anything that takes a property off the market:
# bookings, manual blocks, and events imported from external calendars (Airbnb).
#
# Ranges are half-open [from, to): the check-out / departure day is free, so a
# stay ending on the 14th does not collide with one starting on the 14th.
# Two ranges overlap iff  a.from < b.to  AND  a.to > b.from.
module OccupiesDates
  extend ActiveSupport::Concern

  class_methods do
    def occupies_dates(from:, to:)
      scope :overlapping, ->(check_in, check_out) {
        where(arel_table[from].lt(check_out)).where(arel_table[to].gt(check_in))
      }
    end
  end
end
