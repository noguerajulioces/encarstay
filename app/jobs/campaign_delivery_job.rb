# Fans a campaign out to every confirmed subscriber, one email per recipient so
# each is retried independently by the queue. Marks the campaign sent when done.
class CampaignDeliveryJob < ApplicationJob
  queue_as :default

  def perform(campaign)
    return unless campaign.sending?

    count = 0
    Subscriber.confirmed.find_each do |subscriber|
      NewsletterMailer.with(campaign: campaign, subscriber: subscriber).campaign.deliver_later
      count += 1
    end

    campaign.update!(status: :sent, sent_at: Time.current, recipients_count: count)
  end
end
