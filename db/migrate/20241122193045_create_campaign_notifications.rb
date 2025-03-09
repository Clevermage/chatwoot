class CreateCampaignNotifications < ActiveRecord::Migration[7.0]
  def change
    create_table :campaign_notifications do |t|
      t.references :campaign, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.string :code_cart
      t.string :notification_method
      t.datetime :sent_at
      t.string :status
      t.string :type
      t.text :failure_reason
      t.datetime :response_time

      t.timestamps
    end
  end
end
