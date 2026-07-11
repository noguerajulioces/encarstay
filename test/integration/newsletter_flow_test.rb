require "test_helper"

class NewsletterFlowTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "footer signup creates a pending subscriber and sends a confirmation email" do
    assert_enqueued_emails 1 do
      assert_difference "Subscriber.count", 1 do
        post subscription_path, params: { variant: "footer", subscriber: { email: "new@example.com" } }
      end
    end

    subscriber = Subscriber.find_by(email: "new@example.com")
    assert subscriber.pending?
    assert_equal "footer", subscriber.source
    assert_redirected_to root_path
  end

  test "turbo stream signup swaps the form for the success panel" do
    post subscription_path, params: { variant: "footer", subscriber: { email: "turbo@example.com" } }, as: :turbo_stream

    assert_response :success
    assert_select "turbo-stream[action=replace][target=newsletter_footer]"
  end

  test "the honeypot silently drops spam without creating a subscriber" do
    assert_no_difference "Subscriber.count" do
      assert_no_enqueued_emails do
        post subscription_path, params: { company: "bot", variant: "footer", subscriber: { email: "bot@example.com" } }
      end
    end
    assert_redirected_to root_path
  end

  test "an invalid email is rejected without creating a subscriber" do
    assert_no_difference "Subscriber.count" do
      post subscription_path, params: { variant: "footer", subscriber: { email: "nope" } }
    end
    assert_redirected_to root_path
  end

  test "confirming an opt-in marks it confirmed, mints a code and sends the welcome email" do
    subscriber = subscribers(:pending)

    assert_enqueued_emails 1 do
      get newsletter_confirm_path(subscriber.confirmation_token)
    end

    assert_response :success
    subscriber.reload
    assert subscriber.confirmed?
    assert subscriber.discount_code.present?
    assert_match subscriber.discount_code, response.body
  end

  test "confirming twice does not re-send the welcome email" do
    subscriber = subscribers(:confirmed)
    assert_no_enqueued_emails do
      get newsletter_confirm_path(subscriber.confirmation_token)
    end
    assert_response :success
  end

  test "an unknown confirmation token is not found" do
    get newsletter_confirm_path("nope-token")
    assert_response :not_found
  end

  test "unsubscribing marks the subscriber unsubscribed" do
    subscriber = subscribers(:confirmed)
    get newsletter_unsubscribe_path(subscriber.unsubscribe_token)

    assert_response :success
    assert subscriber.reload.unsubscribed?
  end

  test "posting an already-confirmed email stays neutral and sends nothing" do
    assert_no_difference "Subscriber.count" do
      assert_no_enqueued_emails do
        post subscription_path, params: { variant: "footer", subscriber: { email: subscribers(:confirmed).email } }
      end
    end
    assert_redirected_to root_path
  end

  test "re-subscribing an unsubscribed email returns it to pending and sends confirmation" do
    subscriber = subscribers(:unsubscribed)

    assert_enqueued_emails 1 do
      post subscription_path, params: { variant: "popup", subscriber: { email: subscriber.email } }
    end

    assert subscriber.reload.pending?
  end

  test "an invitation join link subscribes and confirms the guest with a code" do
    token = Rails.application.message_verifier(:newsletter_invite).generate("newguest@example.com")

    assert_difference "Subscriber.count", 1 do
      get newsletter_join_path(token)
    end

    assert_response :success
    subscriber = Subscriber.find_by(email: "newguest@example.com")
    assert subscriber.confirmed?
    assert_equal "invitation", subscriber.source
    assert subscriber.discount_code.present?
    assert_match subscriber.discount_code, response.body
  end

  test "a tampered invitation token is rejected" do
    get newsletter_join_path("garbage-token")
    assert_response :not_found
  end
end
