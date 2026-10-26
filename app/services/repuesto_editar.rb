class RepuestoEditar
  CAMPOS = %i[cantidad costo_unitario margen proveedor].freeze

  def self.call(repuesto:, atributos:)
    repuesto.orden.with_lock do
      repuesto.lock!
      asegurar_editable!(repuesto)
      cambios = atributos.slice(*CAMPOS)
      rechazar_costo_en_pendiente!(repuesto, cambios)
      aplicar(repuesto, cambios)
      raise ActiveRecord::RecordInvalid, repuesto unless repuesto.valid?

      repuesto.precio_cliente = precio_para(repuesto) if repuesto.valorizado?
      asegurar_adelantos!(repuesto)
      repuesto.save!
      repuesto
    end
  end

  def self.asegurar_editable!(repuesto)
    repuesto.errors.add(:orden, repuesto.orden.estado.to_sym) unless repuesto.orden.abierta?
    repuesto.errors.add(:estado, :ya_quitado) if repuesto.quitado_en.present?
    repuesto.errors.add(:base, :no_editable_rechazado) if repuesto.aprobacion_rechazado?
    raise ActiveRecord::RecordInvalid, repuesto if repuesto.errors.any?
  end

  def self.rechazar_costo_en_pendiente!(repuesto, cambios)
    return unless repuesto.pendiente_de_valorizar?
    return if cambios[:costo_unitario].blank? && cambios[:margen].blank?

    repuesto.errors.add(:base, :costo_en_pendiente)
    raise ActiveRecord::RecordInvalid, repuesto
  end

  def self.aplicar(repuesto, cambios)
    repuesto.cantidad = cambios[:cantidad] if cambios.key?(:cantidad)
    if cambios.key?(:proveedor)
      valor = cambios[:proveedor]
      repuesto.proveedor = valor.is_a?(String) ? valor.squish.presence : valor
    end
    return if repuesto.pendiente_de_valorizar?

    repuesto.costo_unitario = cambios[:costo_unitario] if cambios.key?(:costo_unitario)
    return unless cambios.key?(:margen)

    margen = cambios[:margen]
    margen = margen.squish if margen.is_a?(String)
    repuesto.margen = margen if margen.present?
  end

  def self.precio_para(repuesto)
    (repuesto.costo_unitario * repuesto.cantidad * (1 + repuesto.margen / 100)).round(2)
  end

  def self.asegurar_adelantos!(repuesto)
    precio = repuesto.valorizado? ? repuesto.precio_cliente.to_d : 0
    return if repuesto.orden.alcanza_para_adelantos?(repuesto, precio: precio)

    repuesto.errors.add(:base, :supera_adelantos)
    raise ActiveRecord::RecordInvalid, repuesto
  end

  private_class_method :asegurar_editable!, :rechazar_costo_en_pendiente!, :aplicar, :precio_para,
    :asegurar_adelantos!
end
