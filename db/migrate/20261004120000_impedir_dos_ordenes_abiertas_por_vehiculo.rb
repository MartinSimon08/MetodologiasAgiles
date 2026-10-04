class ImpedirDosOrdenesAbiertasPorVehiculo < ActiveRecord::Migration[8.1]
  def change
    add_index :ordenes, :vehiculo_id, unique: true, where: "estado = 'abierta'",
                                      name: "index_ordenes_on_vehiculo_id_abierta"
  end
end
