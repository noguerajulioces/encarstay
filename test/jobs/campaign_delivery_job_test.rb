require "test_helper"

class CampaignDeliveryJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "sends one email per confirmed subscriber and marks the campaign sent" do
    campaign = Campaign.create!(subject: "Novedades", body: "<div>Hola</div>", status: "sending")
    confirmed = Subscriber.confirmed.count
    assert_operator confirmed, :>, 0

    assert_enqueued_emails confirmed do
      CampaignDeliveryJob.perform_now(campaign)
    end

    campaign.reload
    assert campaign.sent?
    assert_equal confirmed, campaign.recipients_count
    assert campaign.sent_at.present?
  end

  test "does nothing unless the campaign is in the sending state" do
    campaign = Campaign.create!(subject: "Draft", body: "x") # draft
    assert_no_enqueued_emails do
      CampaignDeliveryJob.perform_now(campaign)
    end
    assert campaign.draft?
  end
end
