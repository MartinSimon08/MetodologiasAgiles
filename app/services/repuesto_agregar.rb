class RepuestoAgregar
  def self.call(orden:, registrado_por:, **atributos)
    orden.with_lock do
      armar(orden:, registrado_por:, **atributos).tap(&:save!)
    end
  end

  def self.vista_previa(orden:, registrado_por:, **atributos)
    armar(orden:, registrado_por:, **atributos)
  end

  def self.armar(orden:, registrado_por:, descripcion: nil, cantidad: nil, costo_unitario: nil,
                 repuesto_catalogo_id: nil, margen: nil, proveedor: nil)
    catalogo = RepuestoCatalogo.find(repuesto_catalogo_id) if repuesto_catalogo_id.present?
    repuesto = orden.repuestos.build(
      registrado_por: registrado_por, descripcion: catalogo&.nombre || descripcion,
      cantidad: cantidad, costo_unitario: costo_unitario, proveedor: proveedor,
      margen: margen.nil? ? ConfiguracionTaller.actual.margen_repuestos : margen,
      repuesto_catalogo: catalogo
    )

    repuesto.valid?
    repuesto.errors.add(:orden, "está cerrada") unless orden.abierta?
    raise ActiveRecord::RecordInvalid, repuesto if repuesto.errors.any?

    repuesto.precio_cliente = (repuesto.costo_unitario * repuesto.cantidad * (1 + repuesto.margen / 100)).round(2)
    repuesto
  end
  private_class_method :armar
end
