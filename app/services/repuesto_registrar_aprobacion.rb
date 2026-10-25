class RepuestoRegistrarAprobacion
  def self.call(repuesto:, aprobacion:)
    repuesto.with_lock do
      repuesto.errors.add(:orden, repuesto.orden.estado.to_sym) unless repuesto.orden.abierta?
      repuesto.errors.add(:estado, :ya_quitado) if repuesto.quitado_en.present?
      raise ActiveRecord::RecordInvalid, repuesto if repuesto.errors.any?

      repuesto.update!(aprobacion: aprobacion)
    end

    repuesto
  end
end
