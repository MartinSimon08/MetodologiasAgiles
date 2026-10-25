class RepuestoRegistrarAjuste
  def self.call(repuesto:, registrado_por:, tipo: nil, cantidad: nil, costo_unitario: nil, motivo: nil)
    repuesto.orden.with_lock do
      repuesto.lock!
      ajuste = repuesto.ajustes.build(
        cantidad: cantidad,
        costo_unitario: costo_unitario,
        motivo: motivo,
        registrado_por: registrado_por,
        registrado_en: Time.current
      )
      asignar_tipo(ajuste, tipo)
      ajuste.save!
      ajuste
    end
  end

  def self.asignar_tipo(ajuste, tipo)
    ajuste.tipo = tipo
  rescue ArgumentError
    ajuste.errors.add(:tipo, :inclusion, value: tipo)
    raise ActiveRecord::RecordInvalid, ajuste
  end
  private_class_method :asignar_tipo
end
