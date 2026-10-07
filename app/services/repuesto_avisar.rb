class RepuestoAvisar
  def self.call(orden:, registrado_por:, descripcion: nil, cantidad: nil)
    orden.with_lock do
      repuesto = orden.repuestos.build(
        registrado_por: registrado_por, descripcion: descripcion, cantidad: cantidad,
        estado: :pendiente_de_valorizar
      )

      repuesto.valid?
      repuesto.errors.add(:orden, orden.estado.to_sym) unless orden.abierta?
      raise ActiveRecord::RecordInvalid, repuesto if repuesto.errors.any?

      repuesto.save!
      repuesto
    end
  end
end
