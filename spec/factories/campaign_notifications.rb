FactoryBot.define do
  factory :campaign_notification do
    campaign_id { 1 }
    contact_id { 1 }
    code_cart { 'MyString' }
    notification_method { 'MyString' }
    sent_at { '2024-11-22 16:30:45' }
    status { 'MyString' }
    failure_reason { 'MyText' }
    response_time { '2024-11-22 16:30:45' }
  end
end
