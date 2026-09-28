class RepuestoAgregar
  def self.call(orden:, registrado_por:, descripcion: nil, cantidad: nil, costo_unitario: nil,
                repuesto_catalogo_id: nil, margen: nil, proveedor: nil)
    orden.with_lock do
      catalogo = RepuestoCatalogo.find(repuesto_catalogo_id) if repuesto_catalogo_id.present?
      repuesto = orden.repuestos.build(
        registrado_por: registrado_por, descripcion: catalogo&.nombre || descripcion,
        cantidad: cantidad, costo_unitario: costo_unitario, proveedor: proveedor,
        margen: margen.nil? ? ConfiguracionTaller.actual.margen_repuestos : margen,
        repuesto_catalogo: catalogo || RepuestoCatalogo.new(nombre: descripcion, ultimo_costo: costo_unitario)
      )

      repuesto.valid?
      repuesto.errors.add(:orden, "está cerrada") unless orden.abierta?
      raise ActiveRecord::RecordInvalid, repuesto if repuesto.errors.any?

      catalogo ||= RepuestoCatalogo.create_or_find_by!(nombre: repuesto.descripcion.squish.downcase) do |nuevo|
        nuevo.ultimo_costo = repuesto.costo_unitario
      end

      catalogo.with_lock do
        repuesto.repuesto_catalogo = catalogo
        repuesto.precio_cliente = (repuesto.costo_unitario * repuesto.cantidad * (1 + repuesto.margen / 100)).round(2)
        repuesto.save!
        catalogo.update!(ultimo_costo: repuesto.costo_unitario)
      end

      repuesto
    end
  end
end
