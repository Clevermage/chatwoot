class CreateChatbotFunctions < ActiveRecord::Migration[7.0]
  def change
    create_table :chatbot_functions do |t|
      t.boolean :status, default: false, null: false
      t.string :name
      t.jsonb :code_function
      t.jsonb :settings
      t.text :information
      t.integer :account_id
      t.integer :chatbot_id

      t.timestamps
    end
  end
end
