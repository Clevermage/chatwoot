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
    if update_chatbot
      attach_files if params[:files].present?
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
    if update_chatbot
      attach_files if params[:files].present?
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
    params.permit(:status, :name, :instructions, :qr, :email_business, :phone, :address, :email_notify, :type_chatbot_id, :status_scanqr, files: [])
  end

  def chatbot_params
    params.require(:chatbot).permit(:status, :name, :instructions, :qr, :email_business, :phone, :address, :email_notify, :type_chatbot_id,
                                    :status_scanqr, files: [])
  end

  # Actualiza el chatbot con los parámetros permitidos, excluyendo los archivos
  def update_chatbot
    @chat_bot.update(permitted_params.except(:files))
  end

  # Recorre los archivos y los sube a OpenAI, luego los adjunta al chatbot
  def attach_files
    params[:files].each do |file|
      id_file_openai = upload_file_to_openai(file)
      attach_file_to_chatbot(file, id_file_openai)
      @chat_bot.assign_file_to_vector_store(id_file_openai)
    end
  end

  # Sube el archivo a OpenAI y devuelve el ID del archivo subido
  def upload_file_to_openai(file)
    response = @chat_bot.openai_upload_file(file)
    sleep 1 # Podrías mover esta espera fuera de este método si es necesario
    response['id']
  end

  # Adjunta el archivo al chatbot con su metadata de OpenAI
  def attach_file_to_chatbot(file, openai_file_id)
    file_io = File.open(file)
    content_type = Marcel::MimeType.for(file_io)

    @chat_bot.files.attach(
      io: file_io,
      filename: file.original_filename,
      content_type: content_type,
      metadata: { openai_file_id: openai_file_id }
    )
    file_io.close
  end
end
