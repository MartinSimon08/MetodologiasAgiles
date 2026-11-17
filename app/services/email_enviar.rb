require "net/http"
require "json"

class EmailEnviar
  RESEND_URL = "https://api.resend.com/emails".freeze
  BREVO_URL = "https://api.brevo.com/v3/smtp/email".freeze
  ERRORES_DE_RED = [ SocketError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout ].freeze

  def self.remitente
    ENV["MAIL_REMITENTE"].presence
  end

  def self.call(destinatario:, asunto:, texto:)
    return false if remitente.nil?

    por_resend(destinatario, asunto, texto) || por_brevo(destinatario, asunto, texto)
  end

  def self.por_resend(destinatario, asunto, texto)
    clave = ENV["RESEND_API_KEY"].presence
    return false unless clave

    enviar("Resend", RESEND_URL, { "Authorization" => "Bearer #{clave}" },
           { from: remitente, to: [ destinatario ], subject: asunto, text: texto })
  end

  def self.por_brevo(destinatario, asunto, texto)
    clave = ENV["BREVO_API_KEY"].presence
    return false unless clave

    enviar("Brevo", BREVO_URL, { "api-key" => clave },
           { sender: { email: remitente }, to: [ { email: destinatario } ], subject: asunto, textContent: texto })
  end

  def self.enviar(proveedor, url, cabeceras, cuerpo)
    uri = URI(url)
    respuesta = Net::HTTP.post(uri, cuerpo.to_json, cabeceras.merge("Content-Type" => "application/json"))
    return true if respuesta.is_a?(Net::HTTPSuccess)

    Rails.logger.warn("[Email] #{proveedor} #{respuesta.code}: #{respuesta.body}")
    false
  rescue *ERRORES_DE_RED => e
    Rails.logger.warn("[Email] #{proveedor} #{e.class}: #{e.message}")
    false
  end

  private_class_method :por_resend, :por_brevo, :enviar
end
