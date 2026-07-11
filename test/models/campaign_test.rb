require "test_helper"

class CampaignTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "requires a subject" do
    assert_not Campaign.new.valid?
    assert Campaign.new(subject: "Hola").valid?
  end

  test "deliver! launches a draft and flips it to sending" do
    campaign = Campaign.create!(subject: "Oferta", body: "<div>Hola</div>")
    assert campaign.draft?

    assert_enqueued_with(job: CampaignDeliveryJob) do
      assert campaign.deliver!
    end
    assert campaign.sending?
  end

  test "deliver! is a no-op once a campaign has left draft" do
    campaign = Campaign.create!(subject: "Oferta", body: "x", status: "sent")
    assert_no_enqueued_jobs only: CampaignDeliveryJob do
      assert_not campaign.deliver!
    end
  end

  test "editable only while draft" do
    campaign = Campaign.create!(subject: "X", body: "y")
    assert campaign.editable?
    campaign.update!(status: :sent)
    assert_not campaign.editable?
  end
end
