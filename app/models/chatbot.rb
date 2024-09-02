# == Schema Information
#
# Table name: chatbots
#
#  id                  :bigint           not null, primary key
#  actions             :jsonb
#  address             :string
#  api_key_content     :string
#  content             :json
#  email_business      :text
#  email_notify        :string
#  name_business       :string
#  openai_model        :string
#  openai_temperature  :string
#  phone               :string
#  promts              :text
#  qr                  :string
#  status              :boolean          default(FALSE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :integer          not null
#  openai_assistant_id :string
#  type_chatbot_id     :bigint
#
# Indexes
#
#  index_chatbots_on_account_id       (account_id)
#  index_chatbots_on_type_chatbot_id  (type_chatbot_id)
#
class Chatbot < ApplicationRecord
  belongs_to :type_chatbot
  has_many_attached :files
end
