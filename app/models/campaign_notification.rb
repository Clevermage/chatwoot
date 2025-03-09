# == Schema Information
#
# Table name: campaign_notifications
#
#  id                  :bigint           not null, primary key
#  code_cart           :string
#  failure_reason      :text
#  notification_method :string
#  response_time       :datetime
#  sent_at             :datetime
#  status              :string
#  type                :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  campaign_id         :bigint           not null
#  contact_id          :bigint           not null
#
# Indexes
#
#  index_campaign_notifications_on_campaign_id  (campaign_id)
#  index_campaign_notifications_on_contact_id   (contact_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#  fk_rails_...  (contact_id => contacts.id)
#
class CampaignNotification < ApplicationRecord
  belongs_to :campaign
  belongs_to :contact

  # Verificar si el cliente ya recibió una notificación reciente
  def self.recently_notified?(contact_id, campaign_id, threshold_hours = 3)
    exists?(['contact_id = ? AND campaign_id = ? AND sent_at >= ?', contact_id, campaign_id, threshold_hours.hours.ago])
  end

  # Evitar múltiples notificaciones para el mismo carrito
  def self.notification_for_cart_exists?(code_cart, campaign_id)
    exists?(code_cart: code_cart, campaign_id: campaign_id)
  end

  # Limite máximo de notificaciones por cliente en un día
  def self.daily_notification_limit_exceeded?(contact_id, campaign_id, limit = 3)
    where(contact_id: contact_id, campaign_id: campaign_id)
      .where('sent_at >= ?', Time.zone.now.beginning_of_day)
      .count >= limit
  end
end
