class AddFieldsToChatbots < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :meta_jwt_token, :string
    add_column :chatbots, :meta_number_id, :string
    add_column :chatbots, :meta_verify_token, :string
    add_column :chatbots, :meta_version, :string
  end
end
