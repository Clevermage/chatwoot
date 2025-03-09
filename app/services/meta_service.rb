require 'httparty'

class MetaService
  include HTTParty
  base_uri 'https://graph.facebook.com/v21.0'

  def initialize(page_id, access_token)
    @page_id = page_id
    @headers = {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json'
    }
  end

  def send_message(to, template_name, language, template_data)
    body = build_message_body(to, template_name, language, template_data)
    ray('request', body.to_json)
    response = send_whatsapp_request(body)
    handle_response(response)
  end

  def find_template_by_name(name)
    templates_response = templates
    # Asegúrate de que `templates_response` sea válido
    return nil unless templates_response && templates_response['data']

    # Busca el template cuyo nombre coincida con el parámetro
    templates_response['data'].find { |template| template['name'] == name }
  end

  def templates
    response = self.class.get("/#{@page_id}/message_templates", headers: @headers)
    if response.success?
      response.parsed_response # Devuelve el cuerpo de la respuesta parseado
    else
      Rails.logger.error("Error en la respuesta del servicio: #{response.code} - #{response.body}")
      nil # Puedes retornar nil o manejarlo según tus necesidades
    end
  rescue StandardError => e
    # Captura cualquier error inesperado
    Rails.logger.error("Excepción capturada: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n")) # Opcional: registra el backtrace completo
    nil # Puedes retornar nil o manejarlo según tus necesidades
  end

  private

  def build_components(template_data)
    template_data.filter_map do |component|
      case component['type']
      when 'HEADER'
        build_header(component)
      when 'BODY'
        build_body(component)
      when 'FOOTER'
        ''
      when 'BUTTONS'
        build_buttons(component).first
      else
        raise "Unsupported component type: #{component['type']}"
      end
    end.compact
  end

  def build_header(component)
    type = component['format'].downcase
    format = extract_format(component)

    case type
    when 'text'
      build_text_header(format)
    when 'image', 'video', 'document'
      build_media_header(type, format)
    else
      raise ArgumentError, "Unsupported header type: #{type}"
    end
  end

  def build_body(component)
    {
      type: 'body',
      parameters: component.dig('example', 'body_text').map do |texts|
        texts.map { |text| { type: 'text', text: text } }
      end.flatten
    }
  end

  def build_buttons(component)
    component['buttons'].map.with_index do |button, index|
      if button['example']
        {
          'type' => 'button',
          'sub_type' => button['type'].downcase, # Transforma a minúsculas
          'index' => index,
          'parameters' => button['example'].map do |example_url|
            {
              'type' => 'text',
              'text' => example_url # Extrae la parte del path de la URL
            }
          end
        }
      end
    end
  end

  def build_message_body(to, template_name, language, template_data)
    components = build_components(template_data)
    ray('component', components)

    {
      messaging_product: 'whatsapp',
      to: to,
      type: 'template',
      template: {
        name: template_name,
        language: { code: language },
        components: components
      }
    }
  end

  def send_whatsapp_request(body)
    self.class.post("/#{@page_id}/messages", headers: @headers, body: body.to_json)
  rescue StandardError => e
    handle_request_exception(e)
  end

  def handle_response(response)
    ray('respuesta servicio', response)

    if response&.success?
      response.parsed_response
    else
      log_error_response(response)
      nil
    end
  end

  def log_error_response(response)
    ray('Error en la respuesta del servicio')
    Rails.logger.error("Error en la respuesta del servicio: #{response.code} - #{response.body}")
  end

  def handle_request_exception(exception)
    ray(exception.message)
    Rails.logger.error("Excepción capturada al enviar mensaje: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))
    nil
  end

  def extract_format(component)
    component.dig('example', 'header_handle') || component.dig('example', 'header_text')
  end

  def build_text_header(format)
    {
      type: 'header',
      parameters: format.flat_map do |texts|
        texts.map { |text| { type: 'text', text: text } }
      end
    }
  end

  def build_media_header(type, format)
    {
      type: 'header',
      parameters: [
        {
          :type => type,
          type => { link: format }
        }
      ]
    }
  end
end
