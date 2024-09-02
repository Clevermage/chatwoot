class AddColumnsToChatbots < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :name_business, :string
    add_reference :chatbots, :type_chatbot
    add_column :chatbots, :content, :json
    add_column :chatbots, :api_key_content, :string
    add_column :chatbots, :openai_assistant_id, :string
    add_column :chatbots, :openai_model, :string
    add_column :chatbots, :openai_temperature, :string
  end
end
