require "test_helper"

class NewsletterMailerTest < ActionMailer::TestCase
  test "campaign email carries one-click List-Unsubscribe headers and the body" do
    campaign = Campaign.create!(subject: "Hola", body: "<div>Contenido especial</div>")
    mail = NewsletterMailer.with(campaign: campaign, subscriber: subscribers(:confirmed)).campaign

    assert_equal "Hola", mail.subject
    assert_includes mail["List-Unsubscribe"].to_s, "/newsletter/unsubscribe/"
    assert_equal "List-Unsubscribe=One-Click", mail["List-Unsubscribe-Post"].to_s
    assert_match "Contenido especial", mail.html_part.body.decoded
  end

  test "welcome email carries the discount code and unsubscribe link" do
    subscriber = subscribers(:confirmed)
    mail = NewsletterMailer.with(subscriber: subscriber).welcome
    assert_match subscriber.discount_code, mail.html_part.body.decoded
    assert_includes mail.html_part.body.decoded, "/newsletter/unsubscribe/"
  end
end
