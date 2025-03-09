class Campaigns::TriggerAbandonedCampaignJob < ApplicationJob
  queue_as :low

  def perform(campaign)
    ray('TriggerAbandonedCampaignJob')
    campaign.abandoned_cart!
  end
end
