class CreateTareas < ActiveRecord::Migration[8.1]
  def change
    create_table :tareas do |t|
      t.references :orden, null: false, foreign_key: true
      t.references :mecanico, null: true, foreign_key: { to_table: :usuarios }
      t.string :descripcion, null: false
      t.string :estado, null: false, default: "pendiente"
      t.datetime :tomada_en
      t.datetime :terminada_en

      t.timestamps
    end

    add_index :tareas, %i[orden_id estado]
  end
end
