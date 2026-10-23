class CreateTareaNotas < ActiveRecord::Migration[8.1]
  def change
    create_table :tarea_notas do |t|
      t.references :tarea, null: false, foreign_key: true
      t.references :registrado_por, null: false, foreign_key: { to_table: :usuarios }
      t.text :contenido, null: false

      t.timestamps
    end
  end
end
