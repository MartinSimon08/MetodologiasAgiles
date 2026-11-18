require "net/http"
require "json"

class EmailEnviar
  RESEND_URL = "https://api.resend.com/emails".freeze
  BREVO_URL = "https://api.brevo.com/v3/smtp/email".freeze
  ERRORES_DE_RED = [ SocketError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout ].freeze

  REMITENTE_CON_NOMBRE = /\A\s*"?([^"<]*?)"?\s*<([^>\s]+)>\s*\z/

  def self.remitente
    ENV["MAIL_REMITENTE"].presence
  end

  def self.datos_remitente
    coincidencia = remitente.match(REMITENTE_CON_NOMBRE)
    return { email: remitente } unless coincidencia

    { name: coincidencia[1].strip.presence, email: coincidencia[2] }.compact
  end

  def self.call(destinatario:, asunto:, texto:, html: nil)
    return false if remitente.nil?

    por_resend(destinatario, asunto, texto, html) || por_brevo(destinatario, asunto, texto, html)
  end

  def self.por_resend(destinatario, asunto, texto, html)
    clave = ENV["RESEND_API_KEY"].presence
    return false unless clave

    enviar("Resend", RESEND_URL, { "Authorization" => "Bearer #{clave}" },
           { from: remitente_resend, to: [ destinatario ], subject: asunto, text: texto, html: html }.compact)
  end

  def self.por_brevo(destinatario, asunto, texto, html)
    clave = ENV["BREVO_API_KEY"].presence
    return false unless clave

    enviar("Brevo", BREVO_URL, { "api-key" => clave },
           { sender: datos_remitente, to: [ { email: destinatario } ], subject: asunto, textContent: texto, htmlContent: html }.compact)
  end

  def self.remitente_resend
    datos = datos_remitente
    datos[:name] ? "#{datos[:name]} <#{datos[:email]}>" : datos[:email]
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

  private_class_method :por_resend, :por_brevo, :remitente_resend, :enviar
end
