class RepuestoRegistrarAprobacion
  def self.call(repuesto:, aprobacion:)
    repuesto.orden.with_lock do
      repuesto.lock!
      repuesto.errors.add(:orden, repuesto.orden.estado.to_sym) unless repuesto.orden.abierta?
      repuesto.errors.add(:estado, :ya_quitado) if repuesto.quitado_en.present?
      raise ActiveRecord::RecordInvalid, repuesto if repuesto.errors.any?

      asegurar_adelantos!(repuesto, aprobacion)
      repuesto.update!(aprobacion: aprobacion)
    end

    repuesto
  end

  def self.asegurar_adelantos!(repuesto, aprobacion)
    return unless aprobacion.to_s == "rechazado"
    return if repuesto.aprobacion_rechazado?
    return if repuesto.orden.alcanza_para_adelantos?(repuesto, precio: 0, incluir_ajustes_del_repuesto: false)

    repuesto.errors.add(:base, :supera_adelantos)
    raise ActiveRecord::RecordInvalid, repuesto
  end
  private_class_method :asegurar_adelantos!
end
