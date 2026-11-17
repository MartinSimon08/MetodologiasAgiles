class CreateCambiosTurno < ActiveRecord::Migration[8.1]
  def change
    create_table :cambios_turno do |t|
      t.references :caso, null: false, foreign_key: true
      t.date :fecha_anterior
      t.date :fecha_nueva, null: false
      t.references :registrado_por, null: false, foreign_key: { to_table: :usuarios }

      t.timestamps
    end

    add_check_constraint :cambios_turno, "fecha_anterior IS NULL OR fecha_anterior <> fecha_nueva",
                         name: "cambios_turno_fecha_distinta"
  end
end
