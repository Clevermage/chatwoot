class AddActionsToChatbots < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :actions, :jsonb
  end
end
