class CreateCorreccionesOrden < ActiveRecord::Migration[8.1]
  def change
    create_table :correcciones_orden do |t|
      t.references :orden, null: false, foreign_key: true
      t.references :usuario, null: false, foreign_key: true
      t.string :campo, null: false
      t.decimal :valor_anterior, precision: 24, scale: 2
      t.decimal :valor_nuevo, precision: 24, scale: 2
      t.text :motivo, null: false
      t.boolean :revision_confirmada, null: false, default: false

      t.timestamps
    end

    add_check_constraint :correcciones_orden, "campo IN ('total_cerrado', 'franquicia')",
                         name: "correcciones_orden_campo_valido"
  end
end
