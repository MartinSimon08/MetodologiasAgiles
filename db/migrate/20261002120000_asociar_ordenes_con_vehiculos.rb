class AsociarOrdenesConVehiculos < ActiveRecord::Migration[8.1]
  def change
    remove_column :ordenes, :vehiculo, :string, null: false
    add_reference :ordenes, :vehiculo, null: false, foreign_key: true
    add_column :ordenes, :motivo, :text, null: false
  end
end
