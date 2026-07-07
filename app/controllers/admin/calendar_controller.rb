class Admin::CalendarController < Admin::BaseController
  def show
    @month = parse_date("#{params[:month]}-01")&.beginning_of_month || Date.current.beginning_of_month
    @days = (@month..@month.end_of_month).to_a
    @properties = Property.alphabetically
    @occupancy = @properties.index_with { |property| occupancy_for(property) }
  end

  private
    # Maps each occupied day in the month to what holds it, for painting the grid.
    def occupancy_for(property)
      map = {}
      window = @month..@month.end_of_month

      property.blocks.each do |block|
        (block.starts_on...block.ends_on).each { |day| map[day] = { type: "block", record: block } if window.cover?(day) }
      end
      property.external_events.each do |event|
        (event.starts_on...event.ends_on).each { |day| map[day] ||= { type: "external" } if window.cover?(day) }
      end
      property.bookings.occupying.each do |booking|
        (booking.check_in...booking.check_out).each { |day| map[day] = { type: booking.source, record: booking } if window.cover?(day) }
      end
      map
    end
end
