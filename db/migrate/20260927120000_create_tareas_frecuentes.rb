class CreateTareasFrecuentes < ActiveRecord::Migration[8.1]
  def change
    create_table :tarea_frecuentes do |t|
      t.string :descripcion, null: false
      t.decimal :precio_sugerido, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :tarea_frecuentes, "lower(descripcion)", unique: true, name: "index_tarea_frecuentes_on_lower_descripcion"
  end
end
