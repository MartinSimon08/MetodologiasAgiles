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
    destinatario = medio.to_s == "email" ? aseguradora.email : aseguradora.telefono
    if destinatario.blank?
      orden.errors.add(:base, :sin_contacto)
      raise ActiveRecord::RecordInvalid, orden
    end

    EnvioPresupuesto.create!(
      orden: orden, aseguradora: aseguradora, enviado_por: enviado_por, medio: medio,
      destinatario: destinatario, enviado_en: Time.current
    )
  end
end
