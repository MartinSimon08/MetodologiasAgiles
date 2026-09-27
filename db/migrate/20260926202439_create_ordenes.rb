class CreateOrdenes < ActiveRecord::Migration[8.1]
  def change
    create_table :ordenes do |t|
      t.string :cliente, null: false
      t.string :vehiculo, null: false
      t.string :estado, null: false, default: "abierta"

      t.timestamps
    end
  end
end
