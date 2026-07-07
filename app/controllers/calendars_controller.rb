class CalendarsController < ApplicationController
  # Public but unguessable: the calendar_token is the only key. Exposes busy dates only.
  def show
    property = Property.find_by!(calendar_token: params[:calendar_token])
    render plain: CalendarFeed.new(property).to_ical, content_type: "text/calendar"
  end
end
