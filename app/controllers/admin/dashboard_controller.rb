class Admin::DashboardController < Admin::BaseController
  def show
    window = Date.current..(Date.current + 7)

    @pending = Booking.pending.chronologically.includes(:property)
    @arrivals = Booking.confirmed.where(check_in: window).chronologically.includes(:property)
    @departures = Booking.confirmed.where(check_out: window).chronologically.includes(:property)
    @sync_alerts = CalendarSource.active.where.not(last_status: [ nil, "ok" ]).includes(:property)
    @occupancy = month_occupancy
  end

  private
    def month_occupancy
      from = Date.current.beginning_of_month
      to = Date.current.end_of_month + 1
      properties = Property.active.to_a
      return 0 if properties.empty?

      occupied = properties.sum { |property| property.occupied_dates(from, to).size }
      capacity = properties.size * Date.current.end_of_month.day
      (occupied * 100.0 / capacity).round
    end
end
