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
        @chat_bot.files.attach(file)
      end
      render json: @chat_bot
    else
      render json: @chat_bot.errors, status: :unprocessable_entity
    end
  end

  def destroy_file
    file_id = params[:file_id]
    file = @chat_bot.files.find(file_id)
    file.purge # Elimina el archivo adjunto

    render json: { status: 'File removed successfully' }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'File not found' }, status: :not_found
  end

  def destroy; end

  private

  def check_authorization
    authorize(@chatbot) if @chatbot.present?
  end

  def chat_bot
    @chat_bot = Chatbot.where(account_id: [nil, Current.account.id]).find(params[:id]) if params[:action] == 'show'
    @chat_bot ||= Current.account.chatbots.find(params[:id])
  end

  def permitted_params
    params.permit(:status, :promts, :qr, :email_business, :phone, :address, :email_notify, :type_chatbot_id, files: [])
  end

  def chatbot_params
    params.require(:chatbot).permit(:status, :promts, :qr, :email_business, :phone, :address, :email_notify, :type_chatbot_id, files: [])
  end
end
