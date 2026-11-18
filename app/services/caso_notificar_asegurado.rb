class CasoNotificarAsegurado
  # MEDIO_POR_DEFECTO = :whatsapp
  MEDIO_POR_DEFECTO = :telegram

  def self.call(caso:, contenido: nil)
    asegurado = caso.asegurado
    personalizado = !contenido.nil?
    contenido ||= "Hola #{asegurado.nombre}, tu vehículo #{caso.vehiculo.patente} ya está listo para retirar. " \
                  "Caso #{caso.numero_siniestro} - #{caso.aseguradora.nombre}."

    notificacion = NotificacionAsegurado.create!(
      caso: caso, medio: MEDIO_POR_DEFECTO, contenido: contenido, enviada_en: Time.current
    )

    TelegramEnviar.call(texto: contenido)
    notificar_por_email(caso, asegurado, contenido, personalizado)

    Rails.logger.info(
      "[NotificacionAsegurado] #{notificacion.medio} a #{asegurado.telefono}: #{notificacion.contenido}"
    )

    notificacion
  end

  def self.notificar_por_email(caso, asegurado, contenido, personalizado)
    return if asegurado.email.blank?

    asunto = "Aviso del taller - Caso #{caso.numero_siniestro}"
    titulo = personalizado ? "Novedades de tu vehículo" : "Tu vehículo está listo para retirar"
    html = MailPlantilla.aviso_asegurado(caso: caso, mensaje: contenido, titulo: titulo)
    unless EmailEnviar.call(destinatario: asegurado.email, asunto: asunto, texto: contenido, html: html)
      Rails.logger.warn("[NotificacionAsegurado] no se pudo enviar el mail a #{asegurado.email}")
      return
    end

    NotificacionAsegurado.create!(caso: caso, medio: :email, contenido: contenido, enviada_en: Time.current)
  end

  private_class_method :notificar_por_email
end
