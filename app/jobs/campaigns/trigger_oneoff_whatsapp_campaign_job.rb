class Campaigns::TriggerOneoffWhatsappCampaignJob < ApplicationJob
  queue_as :low

  def perform(campaign)
    campaign.whatsapp!
  end
end
