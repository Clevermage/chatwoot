require 'json'
class Api::V1::Accounts::ChatbotFunctionsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :chatbot_function, except: [:index, :create, :chatbots]

  def index
    @chatbot_functions = ChatbotFunction.where(account_id: [nil, Current.account.id])
    render json: @chatbot_functions
  end

  def show; end

  def create
    @chatbot_function = Current.account.chatbot_functions.create!(chatbot_params)
  end

  def update
    if @chatbot_function.update(chatbot_params)
      render json: @chatbot_function
    else
      render json: @chatbot_function.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @chatbot_function.destroy!
    head :ok
  end

  def chatbots
    @chatbots = Chatbot.where(account_id: [nil, Current.account.id])
    render json: @chatbots.as_json(only: [:id, :name])
  end

  private

  def check_authorization
    authorize(@chatbot_function) if @chatbot_function.present?
  end

  def chatbot_function
    @chatbot_function = ChatbotFunction.where(account_id: [nil, Current.account.id]).find(params[:id]) if params[:action] == 'show'
    @chatbot_function ||= Current.account.chatbot_functions.find(params[:id])
  end

  def permitted_params
    params.permit(:information, :name, :settings, :status, :chatbot_id, code_function: {})
  end

  def chatbot_params
    params.require(:chatbot_function).permit(:information, :name, :settings, :status, :chatbot_id, code_function: {})
  end
end
