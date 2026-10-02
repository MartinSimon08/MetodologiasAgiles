class OrdenAbrir
  def self.call(vehiculo_id:, motivo:)
    vehiculo = Vehiculo.find_by(id: vehiculo_id)
    Orden.create!(vehiculo: vehiculo, cliente: vehiculo&.cliente, motivo: motivo)
  end
end
