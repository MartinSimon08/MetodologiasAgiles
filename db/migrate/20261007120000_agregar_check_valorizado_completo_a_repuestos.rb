class AgregarCheckValorizadoCompletoARepuestos < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :repuestos,
      "estado <> 'valorizado' OR (costo_unitario IS NOT NULL AND margen IS NOT NULL AND precio_cliente IS NOT NULL)",
      name: "repuestos_valorizado_completo"
  end
end
