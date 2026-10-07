class AgregarEstadoPendienteARepuestos < ActiveRecord::Migration[8.1]
  def change
    change_column_null :repuestos, :costo_unitario, true
    change_column_null :repuestos, :margen, true
    change_column_null :repuestos, :precio_cliente, true

    add_column :repuestos, :estado, :string, null: false, default: "valorizado"
  end
end
