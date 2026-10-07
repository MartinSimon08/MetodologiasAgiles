class RepuestoValorizar
  def self.call(repuesto:, costo_unitario: nil, margen: nil)
    repuesto.orden.with_lock do
      repuesto.lock!
      repuesto.errors.add(:estado, :ya_valorizado) if repuesto.valorizado?
      repuesto.errors.add(:orden, repuesto.orden.estado.to_sym) unless repuesto.orden.abierta?
      raise ActiveRecord::RecordInvalid, repuesto if repuesto.errors.any?

      repuesto.assign_attributes(
        costo_unitario: costo_unitario,
        margen: margen.nil? ? ConfiguracionTaller.actual.margen_repuestos : margen,
        estado: :valorizado
      )

      raise ActiveRecord::RecordInvalid, repuesto unless repuesto.valid?

      repuesto.precio_cliente = (repuesto.costo_unitario * repuesto.cantidad * (1 + repuesto.margen / 100)).round(2)
      repuesto.save!
      repuesto
    end
  end
end
