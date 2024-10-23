class ModifyChatbot < ActiveRecord::Migration[7.0]
  def change
    rename_column :chatbots, :promts, :instructions
    rename_column :chatbots, :api_key_content, :openai_api_key

    add_column :chatbots, :openai_vector_store_id, :string
  end
end
