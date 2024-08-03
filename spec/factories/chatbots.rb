FactoryBot.define do
  factory :chatbot do
    status { false }
    promts { 'MyText' }
    qr { 'MyString' }
    email { 'MyString' }
    phone { 'MyString' }
    address { 'MyString' }
    email_notify { 'MyString' }
    account_id { 1 }
  end
end
