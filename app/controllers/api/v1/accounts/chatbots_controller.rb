class Api::V1::Accounts::ChatbotsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :chat_bot, except: [:index, :create]

  def index
    @chatbots = Chatbot.where(account_id: [nil, Current.account.id])
    render json: @chatbots
  end

  def show; end
  def create; end

  def update
    @chat_bot.update!(permitted_params)
    render json: @chat_bot
  end

  def destroy; end

  private

  def check_authorization
    super(User)
  end

  def chat_bot
    @chat_bot = Chatbot.where(account_id: [nil, Current.account.id]).find(params[:id]) if params[:action] == 'show'
    @chat_bot ||= Current.account.chatbots.find(params[:id])
  end

  def permitted_params
    params.require(:chatbot).permit(:status, :promts, :qr, :email, :phone, :address, :email, :email_notify)
  end
end
