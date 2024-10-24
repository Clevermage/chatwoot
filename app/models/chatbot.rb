# == Schema Information
#
# Table name: chatbots
#
#  id                       :bigint           not null, primary key
#  actions                  :jsonb
#  address                  :string
#  content                  :json
#  email_business           :text
#  email_notify             :string
#  instructions             :text
#  meta_jwt_token           :string
#  meta_verify_token        :string
#  meta_version             :string
#  name                     :string
#  openai_api_key           :string
#  openai_model             :string
#  openai_temperature       :string
#  phone                    :string
#  qr                       :string
#  status                   :boolean          default(FALSE), not null
#  status_scanqr            :boolean
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :integer          not null
#  meta_number_id           :string
#  openai_assistant_id      :string
#  openai_vector_store_id   :string
#  type_chatbot_id          :bigint
#  type_chatbot_provider_id :bigint
#
# Indexes
#
#  index_chatbots_on_account_id                (account_id)
#  index_chatbots_on_type_chatbot_id           (type_chatbot_id)
#  index_chatbots_on_type_chatbot_provider_id  (type_chatbot_provider_id)
#
class Chatbot < ApplicationRecord
  belongs_to :type_chatbot
  belongs_to :type_chatbot_provider
  has_many_attached :files
  has_many :chatbot_functions, dependent: :destroy_async

  after_update :sync_with_openai

  def openai_upload_file(file)
    access_token = openai_api_key
    service = OpenaiService.new(access_token)
    service.upload_file(file)
  end

  def assign_file_to_vector_store(file_id)
    access_token = openai_api_key
    service = OpenaiService.new(access_token)
    service.assign_file_to_vector_store(openai_vector_store_id, file_id)
  end

  def openai_delete_file(file)
    access_token = openai_api_key
    service = OpenaiService.new(access_token)
    service.delete_file(file)
  end

  private

  def sync_with_openai
    access_token = openai_api_key
    service = OpenaiService.new(access_token)

    service.update_assistant(openai_assistant_id, {
                               name: name,
                               instructions: instructions
                             })
  end
end
