class ShopifyJob < ApplicationJob
  queue_as :medium

  def perform; end
end
