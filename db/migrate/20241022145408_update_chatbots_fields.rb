class UpdateChatbotsFields < ActiveRecord::Migration[7.0]
  def change
    rename_column :chatbots, :name_business, :name
    add_reference :chatbots, :type_chatbot_provider
  end
end
