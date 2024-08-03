class CreateChatbots < ActiveRecord::Migration[7.0]
  def change
    create_table :chatbots do |t|
      t.boolean :status, null: false, default: false
      t.text :promts
      t.string :qr
      t.string :email
      t.string :phone
      t.string :address
      t.string :email_notify
      t.integer :account_id, null: false

      t.timestamps
    end

    add_index :chatbots, :account_id, name: 'index_chatbots_on_account_id'
  end
end
