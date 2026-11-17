class AgregarTelegramAEnviosPresupuesto < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :envios_presupuesto,
                            "medio IN ('email', 'whatsapp')",
                            name: "envios_presupuesto_medio_valido"
    add_check_constraint :envios_presupuesto,
                         "medio IN ('email', 'whatsapp', 'telegram')",
                         name: "envios_presupuesto_medio_valido"
  end
end
