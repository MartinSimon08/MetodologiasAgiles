class CreateConfiguracionesTaller < ActiveRecord::Migration[8.1]
  def change
    create_table :configuraciones_taller do |t|
      t.decimal :margen_repuestos, precision: 5, scale: 2, default: 0, null: false
      t.boolean :registro_unico, default: true, null: false

      t.timestamps
    end

    add_index :configuraciones_taller, :registro_unico, unique: true
    add_check_constraint :configuraciones_taller, "registro_unico = TRUE",
                         name: "configuraciones_taller_registro_unico"
    add_check_constraint :configuraciones_taller, "margen_repuestos BETWEEN 0 AND 100",
                         name: "configuraciones_taller_margen_repuestos_valido"
  end
end
