class TelegramEnviar
  API = TelegramApi::API

  def self.chat_id
    ENV["TELEGRAM_CHAT_ID"].presence
  end

  def self.chat_ids
    chat_id.to_s.split(",").map(&:strip).compact_blank
  end

  def self.configurado?
    TelegramApi.token.present? && chat_id.present?
  end

  def self.call(texto:, chat_ids: self.chat_ids, **extra)
    return false if TelegramApi.token.nil? || chat_ids.empty?

    chat_ids.map { |id| enviar(id, texto, extra) }.all?
  end

  def self.enviar(id, texto, extra)
    respuesta = TelegramApi.post("sendMessage", { "chat_id" => id, "text" => texto }.merge(extra.stringify_keys))
    Rails.logger.warn("[Telegram] #{respuesta.code}: #{respuesta.body}") unless respuesta.is_a?(Net::HTTPSuccess)
    respuesta.is_a?(Net::HTTPSuccess)
  rescue SocketError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.warn("[Telegram] #{e.class}: #{e.message}")
    false
  end

  private_class_method :enviar
end
