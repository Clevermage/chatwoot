class ChangeEmailToEmailBusinessInChatbots < ActiveRecord::Migration[7.0]
  def up
    rename_column :chatbots, :email, :email_business
    change_column :chatbots, :email_business, :text
  end

  def down
    change_column :chatbots, :email_business, :string
    rename_column :chatbots, :email_business, :email
  end
end
