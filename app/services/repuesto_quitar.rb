class RepuestoQuitar
  def self.call(repuesto:, quitado_por:)
    repuesto.orden.with_lock do
      repuesto.lock!
      repuesto.errors.add(:orden, repuesto.orden.estado.to_sym) unless repuesto.orden.abierta?
      repuesto.errors.add(:estado, :ya_quitado) if repuesto.quitado_en.present?
      raise ActiveRecord::RecordInvalid, repuesto if repuesto.errors.any?

      repuesto.assign_attributes(quitado_por: quitado_por, quitado_en: Time.current)
      unless repuesto.orden.alcanza_para_adelantos?(repuesto, precio: 0)
        repuesto.errors.add(:base, :supera_adelantos)
        raise ActiveRecord::RecordInvalid, repuesto
      end

      repuesto.save!
      repuesto
    end
  end
end
