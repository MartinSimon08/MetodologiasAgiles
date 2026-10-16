class CreateAjustesRepuesto < ActiveRecord::Migration[8.1]
  def change
    create_table :ajustes_repuesto do |t|
      t.references :repuesto, null: false, foreign_key: true
      t.string :tipo, null: false
      t.integer :cantidad, null: false
      t.decimal :costo_unitario, precision: 12, scale: 2, null: false
      t.decimal :ajuste_costo, precision: 24, scale: 2, null: false
      t.decimal :ajuste_precio_cliente, precision: 24, scale: 2, null: false
      t.decimal :precio_original, precision: 24, scale: 2, null: false
      t.text :motivo, null: false
      t.references :registrado_por, null: false, foreign_key: { to_table: :usuarios }
      t.datetime :registrado_en, null: false

      t.timestamps
    end

    add_check_constraint :ajustes_repuesto, "tipo IN ('devolucion', 'cambio')", name: "ajustes_repuesto_tipo_valido"
    add_check_constraint :ajustes_repuesto, "cantidad > 0", name: "ajustes_repuesto_cantidad_positiva"
    add_check_constraint :ajustes_repuesto, "costo_unitario >= 0", name: "ajustes_repuesto_costo_no_negativo"
    add_check_constraint :ajustes_repuesto, "precio_original >= 0", name: "ajustes_repuesto_precio_original_no_negativo"
  end
end
