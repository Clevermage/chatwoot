class CreateTypeChatbotProviders < ActiveRecord::Migration[7.0]
  def change
    create_table :type_chatbot_providers do |t|
      t.string :name

      t.timestamps
    end
  end
end
