class TriggerScheduledItemsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    # trigger the scheduled campaign jobs
    Campaign.where(campaign_type: :one_off,
                   campaign_status: :active).where(scheduled_at: 3.days.ago..Time.current).all.find_each(batch_size: 100) do |campaign|
      Campaigns::TriggerOneoffCampaignJob.perform_later(campaign)
    end

    ray('Revisando campañas de carros abandonados')

    # Campaign.where(campaign_type: :ongoing,
    #           campaign_status: :active)
    #    .where("trigger_rules->>'type' = ?", "abandoned_cart")
    #    .find_each(batch_size: 100) do |campaign|
    #    Campaigns::TriggerAbandonedCampaignJob.perform_later(campaign)
    # end

    ray('Revisando campañas de whatsapp')

    Campaign.where(campaign_type: :one_off,
                   campaign_status: :active)
            .where("trigger_rules->>'type' = ?", 'whatsapp')
            .find_each(batch_size: 100) do |campaign|
      Campaigns::TriggerOneoffWhatsappCampaignJob.perform_later(campaign)
    end

    # Job to reopen snoozed conversations
    Conversations::ReopenSnoozedConversationsJob.perform_later

    # Job to reopen snoozed notifications
    Notification::ReopenSnoozedNotificationsJob.perform_later

    # Job to auto-resolve conversations
    Account::ConversationsResolutionSchedulerJob.perform_later

    # Job to sync whatsapp templates
    Channels::Whatsapp::TemplatesSyncSchedulerJob.perform_later

    # Job to clear notifications which are older than 1 month
    Notification::RemoveOldNotificationJob.perform_later
  end
end

TriggerScheduledItemsJob.prepend_mod_with('TriggerScheduledItemsJob')
