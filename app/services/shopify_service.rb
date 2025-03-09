require 'time'
class ShopifyService
  def initialize(shop, token)
    format_url = shop.gsub(%r{^https://}, '')
    session = ShopifyAPI::Auth::Session.new(
      shop: format_url,
      access_token: token
    )
    @client = ShopifyAPI::Clients::Graphql::Admin.new(
      session: session
    )
  end

  def abandoned_cart
    query = build_query
    response = @client.query(query: query)
    data = response.body['data']['abandonedCheckouts']['nodes']

    filter_and_process_data(data)
  end

  private

  def build_query
    <<~QUERY
      query AbandonedCheckouts {
        abandonedCheckouts(first: 5) {
          nodes {
            lineItems(first: 1) {
              edges {
                node {
                  title
                  quantity
                  image {
                    url
                  }
                }
              }
            }
            totalPriceSet {
              shopMoney {
                amount
                currencyCode
              }
            }
            abandonedCheckoutUrl
            billingAddress {
              country
            }
            completedAt
            createdAt
            customer {
              firstName
              lastName
              email
              phone
            }
            id
            shippingAddress {
              country
            }
            updatedAt
          }
        }
      }
    QUERY
  end

  def filter_and_process_data(data)
    result = []
    one_hour_ago = 1.hour.ago
    three_days_ago = 15.days.ago

    data.each do |item|
      created_at = Time.zone.parse(item['createdAt']) # Convertimos la fecha a objeto Time
      next unless created_at.between?(three_days_ago, one_hour_ago)

      result += process_item(item, created_at)
    end

    result
  end

  def process_item(item, created_at)
    customer_info = extract_customer_info(item)
    total_price = item['totalPriceSet']['shopMoney']['amount']
    abandoned_checkout_url = item['abandonedCheckoutUrl']
    code_cart = item['id']

    item['lineItems']['edges'].map do |product|
      product_info = extract_product_info(product)
      build_item_hash({ customer_info: customer_info, total_price: total_price, abandoned_checkout_url: abandoned_checkout_url, code_cart: code_cart,
                        product_info: product_info, created_at: created_at })
    end
  end

  def extract_customer_info(item)
    {
      name: item['customer']['firstName'],
      email: item['customer']['email'],
      phone: item['customer']['phone']
    }
  end

  def extract_product_info(product)
    {
      name: product['node']['title'],
      image: product['node']['image']['url']
    }
  end

  def build_item_hash(params)
    customer_info = params[:customer_info]
    total_price = params[:total_price]
    abandoned_checkout_url = params[:abandoned_checkout_url]
    code_cart = params[:code_cart]
    product_info = params[:product_info]
    created_at = params[:created_at]

    {
      code_cart: code_cart,
      customer_name: customer_info[:name],
      customer_email: customer_info[:email],
      customer_phone: customer_info[:phone],
      amount: total_price,
      product_name: product_info[:name],
      product_image: product_info[:image],
      abandoned_checkout_url: abandoned_checkout_url,
      created_at: created_at
    }
  end
end
