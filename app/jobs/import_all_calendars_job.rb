# Fans out one ImportCalendarJob per active source. Invoked on a recurring schedule
# (see config/recurring.yml) every ~30 minutes.
class ImportAllCalendarsJob < ApplicationJob
  queue_as :default

  def perform
    CalendarSource.active.find_each do |source|
      ImportCalendarJob.perform_later(source)
    end
  end
end
