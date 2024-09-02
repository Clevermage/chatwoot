class ChatbotPolicy < ApplicationPolicy
  def index?
    true
  end

  def update?
    true
  end

  def destroy_file?
    true
  end
end
