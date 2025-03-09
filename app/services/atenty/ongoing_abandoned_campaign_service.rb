class Atenty::OngoingAbandonedCampaignService
  pattr_initialize [:campaign!]

  def perform
    ecommerce, whatsapp_business = fetch_integrations
    return unless ecommerce

    config = build_config(ecommerce, whatsapp_business)
    service = initialize_service(config[:platform], config[:ecommerce_url], config[:ecommerce_api_key])
    return unless service

    abandoned_carts = service.abandoned_cart
    process_abandoned_carts(abandoned_carts, config)
  end

  private

  def should_send_notification?(contact_id, campaign_id, code_cart)
    return false if CampaignNotification.recently_notified?(contact_id, campaign_id)
    return false if CampaignNotification.notification_for_cart_exists?(code_cart, campaign_id)
    return false if CampaignNotification.daily_notification_limit_exceeded?(contact_id, campaign_id)

    true
  end

  def create_contact(account, data)
    contact = Contact.create(
      name: data[:customer_name],
      email: data[:customer_email],
      phone_number: data[:customer_phone],
      account_id: account
    )
    contact.persisted? ? contact : nil
  end

  def register_notification(customer, campaign, item)
    notification = CampaignNotification.create(
      campaign_id: campaign.id,
      contact_id: customer.id,
      code_cart: item[:code_cart],
      notification_method: 'whatsapp',
      sent_at: Time.zone.now,
      status: 'sent'
    )
    notification.persisted? ? notification : nil
  end

  def initialize_service(platform, shop_url, token)
    case platform
    when 'shopify'
      ShopifyService.new(shop_url, token)
    end
  end

  def handle_message_error(response)
    ray("Error al enviar mensaje: #{response[:error]}")
  end

  def fetch_integrations
    ecommerce = Integrations::Hook.where("settings ->> 'type' = ?", 'ecommerce').first
    whatsapp_business = Integrations::Hook.where(app_id: 'whatsapp_business').first
    [ecommerce, whatsapp_business]
  end

  def build_config(ecommerce, whatsapp_business)
    {
      meta_jwt_token: whatsapp_business&.settings&.dig('jwt_token'),
      meta_number_id: whatsapp_business&.settings&.dig('number_id'),
      meta_accound_id: whatsapp_business&.settings&.dig('accound_id'),
      platform: ecommerce.app_id,
      ecommerce_url: ecommerce.settings['url_site'],
      ecommerce_api_key: ecommerce.settings['api_key']
    }
  end

  def process_abandoned_carts(abandoned_carts, config)
    abandoned_carts.each do |cart|
      next if cart[:customer_phone].to_s.empty?

      customer = find_or_create_customer(cart)
      next unless customer

      send_notification(cart, customer, config) if should_send_notification?(customer.id, campaign.id, cart[:code_cart])
    end
  end

  def send_notification(cart, customer, config)
    send_method = campaign.trigger_rules['send_method']

    case send_method
    when 'whatsapp'
      send_whatsapp_notification(cart, customer, config)
    when 'sms'
      send_sms_notification(cart, customer)
    else
      ray("Método de envío no soportado: #{send_method}")
    end
  end

  def find_or_create_customer(cart)
    contact = create_contact(campaign.account_id, cart)
    contact || Contact.find_by(phone_number: cart[:customer_phone]).tap do |customer|
      ray('Contacto no creado o no encontrado') if customer.nil?
    end
  end

  def send_whatsapp_notification(cart, customer, config)
    template = fetch_template(config)
    return unless template

    updated_template = replace_variables(template, campaign.trigger_rules['template'], cart)

    response = send_message_to_customer(cart[:customer_phone], updated_template, config)
    process_response(response, customer, cart)
  end

  def fetch_template(config)
    meta_service = MetaService.new(config[:meta_accound_id], config[:meta_jwt_token])
    template = meta_service.find_template_by_name(campaign.trigger_rules['template']['name'])
    ray('Plantilla no encontrada') unless template
    template
  end

  def send_message_to_customer(phone, template, config)
    meta_api = MetaService.new(config[:meta_number_id], config[:meta_jwt_token])
    meta_api.send_message(phone, template['name'], template['language'], template['components'])
  end

  def process_response(response, customer, cart)
    if response['messages'][0]['message_status'] == 'accepted'
      register_notification(customer, campaign, cart)
    else
      ray("Error al enviar mensaje: #{response[:error]}")
    end
  end

  def replace_variables(template, campaign, cart)
    template = template.deep_dup
    campaign_variables = campaign['variables']

    replace_body_variables(template, campaign_variables, cart)
    replace_header_variables(template, campaign_variables, cart)
    replace_button_variables(template, campaign_variables, cart)

    template
  end

  def replace_placeholders(array, data)
    array.map do |item|
      if item.start_with?('%') && item.end_with?('%')
        key = item[1..-2].to_sym # Convertimos la clave extraída a símbolo
        data[key] || item # Intentamos obtener el valor usando el símbolo, si no existe, dejamos el original
      else
        item # Si no tiene %%, lo deja igual
      end
    end
  end

  def replace_url_in_buttons(buttons, new_url)
    buttons.each do |item|
      item['button']['url'] = new_url if item['button']&.key?('url')
    end
    buttons
  end

  def replace_body_variables(template, campaign_variables, cart)
    return unless template['components']

    body_text = campaign_variables['body_text']
    updated_body_text = replace_placeholders(body_text, cart)

    template['components'].each do |component|
      next unless component['type'] == 'BODY'

      component['example']['body_text'] = [updated_body_text]
    end
  end

  def replace_header_variables(template, campaign_variables, cart)
    return unless template['components']

    header_text = campaign_variables['header_text']
    header_handle = campaign_variables['header_image']

    template['components'].each do |component|
      next unless component['type'] == 'HEADER'

      component['example']['header_text'] = [header_text] if header_text.present?
      component['example']['header_handle'] = cart[:product_image] if header_handle.present?
    end
  end

  def replace_button_variables(template, campaign_variables, cart)
    return unless template['components']

    buttons = campaign_variables['buttons']
    updated_buttons = replace_url_in_buttons(buttons, cart[:abandoned_checkout_url])
    return unless updated_buttons

    template['components'].each do |component|
      next unless component['type'] == 'BUTTONS'

      component['buttons'].each_with_index do |button, index|
        update_button_example(button, updated_buttons, index)
      end
    end
  end

  def update_button_example(button, updated_buttons, index)
    button_type = button['type'].downcase
    campaign_button = begin
      updated_buttons[index]['button'][button_type]
    rescue StandardError
      nil
    end

    button['example'] = [campaign_button] if button_type == 'url' && campaign_button.present?
  end
end
