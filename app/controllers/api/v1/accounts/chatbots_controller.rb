require 'json'
class Api::V1::Accounts::ChatbotsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :chat_bot, except: [:index, :create]

  def index
    @chatbots = Chatbot.where(account_id: [nil, Current.account.id])

    chatbots_with_files = @chatbots.map do |chatbot|
      chatbot.as_json(include: :files).merge(
        files: chatbot.files.map do |file|
          {
            id: file.id,
            url: url_for(file),
            name: file.filename.to_s
          }
        end
      )
    end

    render json: chatbots_with_files
  end

  def show; end
  def create; end

  def update
    if @chat_bot.update(permitted_params.except(:files))
      # Adicional: Añade los archivos solo si existen en los parámetros
      params[:files]&.each do |file|
        file_io = File.open(file)
        content_type = Marcel::MimeType.for(file_io)

        # sube el archivo a openai
        response = @chat_bot.openai_upload_file(file)
        sleep 1
        id_file_openai = response['id']

        @chat_bot.files.attach(
          io: file_io, # Archivo que deseas adjuntar
          filename: file.original_filename, # Nombre del archivo
          content_type: content_type, # Tipo de contenido del archivo
          metadata: { openai_file_id: id_file_openai } # Agregar el `openai_file_id` a los metadato
        )

        file_io.close
      end
      render json: @chat_bot
    else
      render json: @chat_bot.errors, status: :unprocessable_entity
    end
  end

  def destroy_file
    file_id = params[:file_id]
    file = @chat_bot.files.find(file_id)
    blob_id = file.blob_id
    blob = ActiveStorage::Blob.find(blob_id)
    openai_file_id = blob.metadata['openai_file_id']
    @chat_bot.openai_delete_file(openai_file_id) unless openai_file_id.nil?
    file.purge
    render json: { status: 'File removed successfully' }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'File not found' }, status: :not_found
  end

  def destroy; end

  def process_file
    if @chat_bot.update(permitted_params.except(:files))

      params[:files]&.each do |file|
        file_io = File.open(file)
        content_type = Marcel::MimeType.for(file_io)

        # sube el archivo a openai
        response = @chat_bot.openai_upload_file(file)
        sleep 1
        id_file_openai = response['id']

        @chat_bot.files.attach(
          io: file_io, # Archivo que deseas adjuntar
          filename: file.original_filename, # Nombre del archivo
          content_type: content_type, # Tipo de contenido del archivo
          metadata: { openai_file_id: id_file_openai } # Agregar el `openai_file_id` a los metadato
        )
        file_io.close
      end
      render json: @chat_bot

    else
      render json: @chat_bot.errors, status: :unprocessable_entity
    end
  end

  private

  def check_authorization
    authorize(@chatbot) if @chatbot.present?
  end

  def chat_bot
    @chat_bot = Chatbot.where(account_id: [nil, Current.account.id]).find(params[:id]) if params[:action] == 'show'
    @chat_bot ||= Current.account.chatbots.find(params[:id])
  end

  def permitted_params
    params.permit(:status, :name_business, :instructions, :qr, :email_business, :phone, :address, :email_notify, :type_chatbot_id, files: [])
  end

  def chatbot_params
    params.require(:chatbot).permit(:status, :name_business, :instructions, :qr, :email_business, :phone, :address, :email_notify, :type_chatbot_id,
                                    files: [])
  end
end
