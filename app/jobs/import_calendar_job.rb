class ImportCalendarJob < ApplicationJob
  queue_as :default

  # One failing feed shouldn't wedge the schedule; its status records the error.
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(calendar_source)
    calendar_source.import!
  end
end
