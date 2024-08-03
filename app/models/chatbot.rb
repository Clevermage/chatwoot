# == Schema Information
#
# Table name: chatbots
#
#  id           :bigint           not null, primary key
#  address      :string
#  email        :string
#  email_notify :string
#  phone        :string
#  promts       :text
#  qr           :string
#  status       :boolean
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#
# Indexes
#
#  index_chatbots_on_account_id  (account_id)
#
class Chatbot < ApplicationRecord
end
