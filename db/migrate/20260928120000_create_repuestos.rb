class CreateRepuestos < ActiveRecord::Migration[8.1]
  def change
    create_table :repuestos_catalogo do |t|
      t.string :nombre, null: false
      t.decimal :ultimo_costo, precision: 12, scale: 2, null: false
      t.timestamps
    end
    add_index :repuestos_catalogo, :nombre, unique: true
    add_check_constraint :repuestos_catalogo, "ultimo_costo >= 0", name: "catalogo_costo_no_negativo"

    create_table :repuestos do |t|
      t.references :orden, null: false, foreign_key: true
      t.references :repuesto_catalogo, null: false, foreign_key: { to_table: :repuestos_catalogo }
      t.references :registrado_por, null: false, foreign_key: { to_table: :usuarios }
      t.string :descripcion, null: false
      t.integer :cantidad, null: false
      t.decimal :costo_unitario, precision: 12, scale: 2, null: false
      t.decimal :margen, precision: 5, scale: 2, null: false
      t.decimal :precio_cliente, precision: 24, scale: 2, null: false
      t.string :proveedor
      t.timestamps
    end
    add_check_constraint :repuestos, "cantidad > 0", name: "repuestos_cantidad_positiva"
    add_check_constraint :repuestos, "costo_unitario >= 0", name: "repuestos_costo_no_negativo"
    add_check_constraint :repuestos, "margen >= 0 AND margen <= 100", name: "repuestos_margen_valido"
  end
end
