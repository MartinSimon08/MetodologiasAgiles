class PresupuestoEnviar
  def self.call(orden:, medio:, enviado_por:)
    unless orden.abierta?
      orden.errors.add(:base, :presupuesto_no_disponible)
      raise ActiveRecord::RecordInvalid, orden
    end

    caso = Caso.find_by(orden_id: orden.id)
    if caso.nil?
      orden.errors.add(:base, :sin_caso)
      raise ActiveRecord::RecordInvalid, orden
    end

    aseguradora = caso.aseguradora
    # destinatario = medio.to_s == "email" ? aseguradora.email : aseguradora.telefono
    destinatario = medio.to_s == "email" ? aseguradora.email : aseguradora.telegram_chat_id
    if destinatario.blank?
      orden.errors.add(:base, medio.to_s == "telegram" ? :sin_telegram : :sin_contacto)
      raise ActiveRecord::RecordInvalid, orden
    end

    datos = OrdenCalcularPresupuesto.call(orden: orden)
    texto = mensaje(orden, caso, datos)
    unless entregar(medio.to_s, destinatario, orden, caso, datos, texto)
      orden.errors.add(:base, :envio_fallido)
      raise ActiveRecord::RecordInvalid, orden
    end

    EnvioPresupuesto.create!(
      orden: orden, aseguradora: aseguradora, enviado_por: enviado_por, medio: medio,
      destinatario: destinatario, enviado_en: Time.current
    )
  end

  def self.entregar(medio, destinatario, orden, caso, datos, texto)
    case medio
    when "email"
      EmailEnviar.call(destinatario: destinatario, asunto: "Presupuesto orden ##{orden.id}", texto: texto,
                       html: MailPlantilla.presupuesto(orden: orden, caso: caso, presupuesto: datos))
    when "telegram" then TelegramEnviar.call(texto: texto, chat_ids: [ destinatario ])
    else true
    end
  end

  def self.mensaje(orden, caso, datos)
    total = datos.total_aseguradora.to_d.to_s("F")
    [
      "Presupuesto de la orden ##{orden.id}",
      "Siniestro #{caso.numero_siniestro}",
      "Total para la aseguradora: $ #{total}"
    ].join("\n")
  end
end
