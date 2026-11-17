class CasoNotificarAsegurado
  # MEDIO_POR_DEFECTO = :whatsapp
  MEDIO_POR_DEFECTO = :telegram

  def self.call(caso:)
    asegurado = caso.asegurado
    contenido = "Hola #{asegurado.nombre}, tu vehículo #{caso.vehiculo.patente} ya está listo para retirar. " \
                "Caso #{caso.numero_siniestro} - #{caso.aseguradora.nombre}."

    notificacion = NotificacionAsegurado.create!(
      caso: caso, medio: MEDIO_POR_DEFECTO, contenido: contenido, enviada_en: Time.current
    )

    TelegramEnviar.call(texto: contenido)

    Rails.logger.info(
      "[NotificacionAsegurado] #{notificacion.medio} a #{asegurado.telefono}: #{notificacion.contenido}"
    )

    notificacion
  end
end
