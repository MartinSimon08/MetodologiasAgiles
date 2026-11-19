require "json"

class TelegramSincronizar
  BOTON_CONTACTO = {
    keyboard: [ [ { text: "Compartir mi contacto", request_contact: true } ] ],
    resize_keyboard: true,
    one_time_keyboard: true
  }.to_json.freeze
  SIN_TECLADO = { remove_keyboard: true }.to_json.freeze

  def self.call(timeout: 0)
    return 0 if TelegramApi.token.nil?

    respuesta = TelegramApi.post("getUpdates", "timeout" => timeout)
    unless respuesta.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("[Telegram] getUpdates #{respuesta.code}: #{respuesta.body}")
      return 0
    end

    actualizaciones = JSON.parse(respuesta.body).fetch("result")
    return 0 if actualizaciones.empty?

    actualizaciones.each { |actualizacion| procesar(actualizacion["message"]) }
    TelegramApi.post("getUpdates", "offset" => actualizaciones.last["update_id"] + 1, "timeout" => 0)
    actualizaciones.size
  rescue SocketError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout, JSON::ParserError => e
    Rails.logger.warn("[Telegram] #{e.class}: #{e.message}")
    0
  end

  def self.procesar(mensaje)
    return if mensaje.nil? || mensaje.dig("chat", "type") != "private"

    chat_id = mensaje.dig("chat", "id").to_s
    contacto = mensaje["contact"]

    if contacto.nil?
      TelegramEnviar.call(
        texto: "Hola. Para recibir los avisos del taller, compartí tu contacto con el botón de abajo.",
        chat_ids: [ chat_id ], reply_markup: BOTON_CONTACTO
      )
    elsif contacto["user_id"] != mensaje.dig("from", "id")
      TelegramEnviar.call(texto: "Compartí tu propio contacto, no el de otra persona.", chat_ids: [ chat_id ])
    else
      vincular(chat_id, contacto["phone_number"])
    end
  end

  def self.vincular(chat_id, telefono)
    clave = solo_digitos(telefono).last(10)
    contactos = clave.length < 6 ? [] : coincidentes(Aseguradora, clave) + coincidentes(Cliente, clave)

    if contactos.empty?
      TelegramEnviar.call(texto: "No encontramos ese número en ninguna aseguradora ni cliente del taller.",
                          chat_ids: [ chat_id ], reply_markup: SIN_TECLADO)
    else
      contactos.each { |contacto| contacto.update_columns(telegram_chat_id: chat_id) }
      TelegramEnviar.call(texto: "Listo, quedaste vinculado como contacto de #{contactos.map(&:nombre).join(', ')}. " \
                                 "Te vamos a avisar por acá.", chat_ids: [ chat_id ], reply_markup: SIN_TECLADO)
    end
  end

  def self.coincidentes(modelo, clave)
    modelo.where.not(telefono: nil).select { |contacto| solo_digitos(contacto.telefono).last(10) == clave }
  end

  def self.solo_digitos(valor)
    valor.to_s.gsub(/\D/, "")
  end

  private_class_method :procesar, :vincular, :coincidentes, :solo_digitos
end
