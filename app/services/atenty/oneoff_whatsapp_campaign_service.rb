class Atenty::OneoffWhatsappCampaignService
  pattr_initialize [:campaign!]

  def perform
    validate_campaign
    campaign.completed!
    whatsapp_business = fetch_integrations
    return unless whatsapp_business

    config = build_config(whatsapp_business)
    ray('config', config)

    audience_labels = fetch_audience_labels
    process_audience(audience_labels, config)
  end

  private

  def validate_campaign
    raise "Invalid campaign #{campaign.id}" unless valid_campaign?
    raise 'Completed Campaign' if campaign.completed?
  end

  def valid_campaign?
    campaign.inbox.name == 'BOTWS' && campaign.one_off?
  end

  def fetch_audience_labels
    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
    campaign.account.labels.where(id: audience_label_ids).pluck(:title)
  end

  def process_audience(audience_labels, config)
    campaign.account.contacts.tagged_with(audience_labels, any: true).each do |contact|
      next if contact.phone_number.blank?

      send_message(contact, config)
    end
  end

  def send_message(contact, config)
    template = fetch_template(config)
    return unless template

    data = ''

    updated_template = replace_variables(template, campaign.trigger_rules['template'], data)
    ray('update template', updated_template)
    ray('contacto', contact)

    response = send_message_to_customer(contact.phone_number, updated_template, config)

    process_response(response, contact)
  end

  def register_notification(contact, campaign)
    ray('registrando notificacion')
    notification = CampaignNotification.create(
      campaign_id: campaign.id,
      contact_id: contact.id,
      notification_method: 'whatsapp',
      sent_at: Time.zone.now,
      status: 'sent'
    )
    notification.persisted? ? notification : nil
  end

  def handle_message_error(response)
    ray("Error al enviar mensaje: #{response[:error]}")
  end

  def log_campaign_details
    ray('campaña', campaign)
    ray('método de envío', campaign.trigger_rules['send_method'])
  end

  def fetch_integrations
    whatsapp_business = Integrations::Hook.where(app_id: 'whatsapp_business').first
    [whatsapp_business]
  end

  def build_config(whatsapp_business)
    ray('whatsapp_business', whatsapp_business)
    {
      meta_jwt_token: whatsapp_business[0]['settings']['jwt_token'],
      meta_number_id: whatsapp_business[0]['settings']['number_id'],
      meta_accound_id: whatsapp_business[0]['settings']['accound_id']
    }
  end

  def fetch_template(config)
    meta_service = MetaService.new(config[:meta_accound_id], config[:meta_jwt_token])
    template = meta_service.find_template_by_name(campaign.trigger_rules['template']['name'])
    ray('Plantilla no encontrada') unless template
    template
  end

  def send_message_to_customer(phone, template, config)
    meta_api = MetaService.new(config[:meta_number_id], config[:meta_jwt_token])
    ray('meta api', meta_api)
    meta_api.send_message(phone, template['name'], template['language'], template['components'])
  end

  def process_response(response, customer)
    if response['messages'][0]['message_status'] == 'accepted'
      ray("Mensaje enviado exitosamente: #{response[:data]}")
      register_notification(customer, campaign)
    else
      ray("Error al enviar mensaje: #{response[:error]}")
    end
  end

  def replace_variables(template, campaign, data)
    template = template.deep_dup
    campaign_variables = campaign['variables']
    ray('campaign var', campaign_variables)

    replace_body_variables(template, campaign_variables, data)
    replace_header_variables(template, campaign_variables)
    replace_button_variables(template)

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

  def replace_body_variables(template, campaign_variables, data)
    return unless template['components']

    body_text = campaign_variables['body_text']
    updated_body_text = replace_placeholders(body_text, data)

    template['components'].each do |component|
      next unless component['type'] == 'BODY'

      component['example']['body_text'] = [updated_body_text]
    end
  end

  def replace_header_variables(template, campaign_variables)
    return unless template['components']

    header_text = campaign_variables['header_text']
    header_handle = campaign_variables['header_image']

    template['components'].each do |component|
      next unless component['type'] == 'HEADER'

      component['example']['header_text'] = [header_text] if header_text.present?
      component['example']['header_handle'] = header_handle if header_handle.present?
    end
  end

  def replace_button_variables(template)
    return unless template['components']

    updated_buttons = 'https://5y5g8k-q4.myshopify.com'
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
