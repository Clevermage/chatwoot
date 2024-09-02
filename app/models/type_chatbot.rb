# == Schema Information
#
# Table name: type_chatbots
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class TypeChatbot < ApplicationRecord
  has_many :chatbots, dependent: :destroy
end
