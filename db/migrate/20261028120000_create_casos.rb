class CreateCasos < ActiveRecord::Migration[8.1]
  def change
    create_table :casos do |t|
      t.references :aseguradora, null: false, foreign_key: true, index: false
      t.references :asegurado, null: false, foreign_key: { to_table: :clientes }
      t.references :vehiculo, null: false, foreign_key: true
      t.references :orden, foreign_key: { to_table: :ordenes }, index: { unique: true }
      t.string :numero_siniestro, null: false
      t.text :descripcion
      t.date :fecha_turno

      t.timestamps
    end

    add_index :casos, %i[aseguradora_id numero_siniestro], unique: true
  end
end
