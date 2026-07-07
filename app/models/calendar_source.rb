require "net/http"

class CalendarSource < ApplicationRecord
  belongs_to :property
  has_many :external_events, dependent: :destroy

  scope :active, -> { where(active: true) }
  scope :stale, -> { active.where("last_synced_at IS NULL OR last_synced_at < ?", 2.hours.ago) }

  validates :name, presence: true
  validates :ical_url, presence: true

  # Downloads the .ics and imports it, recording sync status. Any error is captured
  # in last_status (and re-raised so the job can retry).
  def import!
    import_from(fetch_ical)
    update!(last_synced_at: Time.current, last_status: "ok")
  rescue => error
    update!(last_synced_at: Time.current, last_status: "error: #{error.message}".truncate(150))
    raise
  end

  # Upserts events by UID, drops the ones that vanished from the feed (= cancelled
  # upstream), and raises a collision alert for any new/changed event that overlaps
  # a direct booking. Separated from the HTTP fetch so it can be tested directly.
  def import_from(ical_string)
    calendars = Icalendar::Calendar.parse(ical_string)
    alert_collisions(sync_events(calendars.flat_map(&:events)))
  end

  private
    def fetch_ical
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 15) do |http|
        http.get(uri.request_uri)
      end
      response.value # raises unless 2xx
      response.body
    end

    def uri
      @uri ||= URI.parse(ical_url)
    end

    def sync_events(events)
      seen_uids = []
      changed = []

      events.each do |event|
        uid = event.uid.to_s.presence or next
        starts_on = event.dtstart&.to_date
        ends_on = event.dtend&.to_date
        next unless starts_on && ends_on

        record = external_events.find_or_initialize_by(uid: uid)
        record.assign_attributes(starts_on: starts_on, ends_on: ends_on,
          summary: event.summary.to_s.presence, raw_payload: event.to_ical)
        changed << record if record.new_record? || record.changed?
        record.save!
        seen_uids << uid
      end

      external_events.where.not(uid: seen_uids).destroy_all if seen_uids.any?
      external_events.destroy_all if seen_uids.empty?
      changed
    end

    def alert_collisions(events)
      events.each do |event|
        property.bookings.occupying.overlapping(event.starts_on, event.ends_on).find_each do |booking|
          BookingMailer.with(booking: booking, event: event).collision_alert.deliver_later
        end
      end
    end
end
