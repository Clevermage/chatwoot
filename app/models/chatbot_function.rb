# == Schema Information
#
# Table name: chatbot_functions
#
#  id            :bigint           not null, primary key
#  code_function :jsonb
#  information   :text
#  name          :string
#  settings      :jsonb
#  status        :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer
#  chatbot_id    :integer
#
class ChatbotFunction < ApplicationRecord
  belongs_to :chatbot

  after_create :sync_with_openai
  after_update :sync_with_openai
  after_destroy :sync_with_openai

  private

  def sync_with_openai
    access_token = chatbot.openai_api_key
    service = OpenaiService.new(access_token)
    tools = []

    chatbot.chatbot_functions.each do |function|
      tools << {
        type: 'function',
        function: function.code_function
      }
    end

    service.update_assistant(chatbot.openai_assistant_id, {
                               name: chatbot.name,
                               instructions: chatbot.instructions,
                               tools: tools
                             })
  end
end
