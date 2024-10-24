class AddChatbotsFields < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :status_scanqr, :boolean, default: false, null: false
  end
end
