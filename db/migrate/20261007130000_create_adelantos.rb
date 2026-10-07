class CreateAdelantos < ActiveRecord::Migration[8.1]
  def change
    create_table :adelantos do |t|
      t.references :orden, null: false, foreign_key: true
      t.decimal :importe, precision: 12, scale: 2, null: false
      t.datetime :registrado_en, null: false
      t.references :registrado_por, null: false, foreign_key: { to_table: :usuarios }

      t.timestamps
    end

    add_check_constraint :adelantos, "importe > 0", name: "adelantos_importe_positivo"
  end
end
