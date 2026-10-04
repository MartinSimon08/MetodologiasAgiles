class OrdenAbrir
  def self.call(vehiculo_id:, motivo:)
    vehiculo = Vehiculo.find_by(id: vehiculo_id)
    orden = Orden.new(vehiculo: vehiculo, cliente: vehiculo&.cliente, motivo: motivo)
    orden.save!
    orden
  rescue ActiveRecord::RecordNotUnique
    orden.errors.add(:vehiculo, :con_orden_abierta)
    raise ActiveRecord::RecordInvalid, orden
  end
end
