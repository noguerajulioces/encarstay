require "test_helper"

class SubscriberTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "normalizes email to stripped lowercase" do
    subscriber = Subscriber.create!(email: "  NEW@Example.COM ")
    assert_equal "new@example.com", subscriber.email
  end

  test "requires a valid, unique email" do
    assert_not Subscriber.new(email: "not-an-email").valid?

    dup = Subscriber.new(email: subscribers(:pending).email)
    assert_not dup.valid?
    assert_includes dup.errors.attribute_names, :email
  end

  test "generates both tokens on create" do
    subscriber = Subscriber.create!(email: "tokens@example.com")
    assert subscriber.confirmation_token.present?
    assert subscriber.unsubscribe_token.present?
  end

  test "confirm! sets confirmed_at, mints a discount code, and is idempotent" do
    subscriber = subscribers(:pending)
    subscriber.confirm!

    assert subscriber.confirmed?
    assert subscriber.confirmed_at.present?
    code = subscriber.discount_code
    assert code.present?

    subscriber.confirm! # must not re-issue
    assert_equal code, subscriber.reload.discount_code
  end

  test "unsubscribe! marks the record unsubscribed" do
    subscriber = subscribers(:confirmed)
    subscriber.unsubscribe!

    assert subscriber.unsubscribed?
    assert subscriber.unsubscribed_at.present?
  end

  test "resubscribe! returns an unsubscribed record to pending with a fresh token" do
    subscriber = subscribers(:unsubscribed)
    old_token = subscriber.confirmation_token
    subscriber.resubscribe!

    assert subscriber.pending?
    assert_nil subscriber.unsubscribed_at
    assert_not_equal old_token, subscriber.confirmation_token
  end

  test "invite_past_guests! emails distinct past guests that aren't already subscribed" do
    property = properties(:lago)
    property.book!(check_in: Date.current + 60, check_out: Date.current + 63, guests_count: 2,
      guest_name: "Vieja Clienta", guest_email: "guest@example.com", locale: "es")
    # A guest who is already a subscriber must be skipped.
    property.book!(check_in: Date.current + 70, check_out: Date.current + 73, guests_count: 2,
      guest_name: "Ya Suscrito", guest_email: subscribers(:confirmed).email, locale: "es")

    assert_enqueued_emails 1 do
      assert_equal 1, Subscriber.invite_past_guests!
    end
  end
end
