# == Schema Information
#
# Table name: type_chatbot_providers
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class TypeChatbotProvider < ApplicationRecord
  has_many :chatbots, dependent: :destroy
end
