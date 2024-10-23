require 'openai'
require 'httparty'

class OpenaiService
  include HTTParty
  base_uri 'https://api.openai.com'

  def initialize(access_token)
    @client = OpenAI::Client.new(
      access_token: access_token,
      log_errors: true
    )
    @options = {
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{access_token}"
      }
    }
  end

  def assistant_list
    @client.assistants.list
  end

  def create_assistant(params)
    @client.assistants.create(params)
  end

  def update_assistant(assistant_id, params)
    @client.assistants.modify(
      id: assistant_id,
      parameters: params
    )
  end

  def vector_list
    @client.vector_stores.list
  end

  def create_vector_file
    client.vector_stores.create(params)
  end

  def upload_file(file)
    @client.files.upload(parameters: { file: file, purpose: 'assistants' })
  end

  def delete_file(file_id)
    response = self.class.delete("/v1/files/#{file_id}", @options)
    if response.success?
      response.parsed_response # Devuelve el cuerpo de la respuesta parseado
      ray('RESPONSE SUSCC', response)
    else
      Rails.logger.error 'error servicio'
    end
  end

  def create_project(project_name)
    body = {
      name: project_name
    }.to_json

    self.class.post('/v1/organization/projects', headers: @headers, body: body)
  end
end
