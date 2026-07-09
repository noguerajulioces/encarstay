# A marketing-list contact captured from the footer form or the site popup.
# Double opt-in: a subscriber is created `pending` and only becomes `confirmed`
# after clicking the link in the confirmation email, at which point they earn a
# one-off welcome discount code. Every marketing email carries an unsubscribe
# link. Sending campaigns is a later phase — this model just owns the list.
class Subscriber < ApplicationRecord
  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  has_secure_token :confirmation_token
  has_secure_token :unsubscribe_token

  enum :status, %w[ pending confirmed unsubscribed ].index_with(&:itself), default: :pending
  enum :source, %w[ footer popup invitation ].index_with(&:itself), default: :footer

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }

  scope :chronologically, -> { order(created_at: :desc) }

  # Turn a pending opt-in into a confirmed subscriber and mint their welcome
  # discount code. Idempotent so link scanners / double clicks don't re-issue.
  def confirm!
    return if confirmed?
    update!(status: :confirmed, confirmed_at: Time.current, discount_code: generate_discount_code)
  end

  def unsubscribe!
    return if unsubscribed?
    update!(status: :unsubscribed, unsubscribed_at: Time.current)
  end

  # A previously-unsubscribed address opting back in must confirm again, so we
  # reset to pending with a fresh token.
  def resubscribe!
    regenerate_confirmation_token
    update!(status: :pending, unsubscribed_at: nil)
  end

  # One-time re-engagement: email every past guest who isn't already on the list
  # a single opt-in invitation. They only join if they click their personalised
  # link — we never bulk-import them (they consented to transactional mail, not
  # marketing). Returns how many invitations were sent.
  def self.invite_past_guests!
    existing = pluck(:email).to_set
    seen = {}
    Booking.pluck(:guest_email, :locale).each do |raw_email, locale|
      email = raw_email.to_s.strip.downcase
      next if email.blank? || existing.include?(email) || seen.key?(email)
      seen[email] = locale.presence || I18n.default_locale.to_s
    end
    seen.each { |email, locale| NewsletterMailer.with(email: email, locale: locale).invitation.deliver_later }
    seen.size
  end

  def self.to_csv
    require "csv"
    CSV.generate do |csv|
      csv << %w[email status source locale confirmed_at discount_code discount_redeemed_at created_at]
      chronologically.find_each do |subscriber|
        csv << [ subscriber.email, subscriber.status, subscriber.source, subscriber.locale,
                 subscriber.confirmed_at, subscriber.discount_code, subscriber.discount_redeemed_at,
                 subscriber.created_at ]
      end
    end
  end

  private
    def generate_discount_code
      loop do
        candidate = "ENCAR-#{SecureRandom.alphanumeric(6).upcase}"
        break candidate unless Subscriber.exists?(discount_code: candidate)
      end
    end
end
