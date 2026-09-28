class CreateVehiculos < ActiveRecord::Migration[8.1]
  def change
    create_table :vehiculos do |t|
      t.references :cliente, null: false, foreign_key: true
      t.string :patente, null: false
      t.string :marca
      t.string :modelo
      t.integer :anio
      t.integer :kilometraje
      t.timestamps
    end
    add_index :vehiculos, :patente, unique: true
    add_check_constraint :vehiculos, "kilometraje >= 0", name: "vehiculos_kilometraje_no_negativo"
  end
end
