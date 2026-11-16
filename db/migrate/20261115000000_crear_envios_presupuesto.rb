class CrearEnviosPresupuesto < ActiveRecord::Migration[8.1]
  def change
    create_table :envios_presupuesto do |t|
      t.references :orden, null: false, foreign_key: true
      t.references :aseguradora, null: false, foreign_key: true
      t.references :enviado_por, null: false, foreign_key: { to_table: :usuarios }
      t.string :medio, null: false
      t.string :destinatario, null: false
      t.datetime :enviado_en, null: false
      t.timestamps
    end

    add_check_constraint :envios_presupuesto,
                         "medio IN ('email', 'whatsapp')",
                         name: "envios_presupuesto_medio_valido"
  end
end
