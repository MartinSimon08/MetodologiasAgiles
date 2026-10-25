class RegistrarBajaDeRepuestos < ActiveRecord::Migration[8.1]
  def change
    add_reference :repuestos, :quitado_por, foreign_key: { to_table: :usuarios }
    add_column :repuestos, :quitado_en, :datetime
    add_check_constraint :repuestos,
      "(quitado_en IS NULL) = (quitado_por_id IS NULL)",
      name: "repuestos_quitado_consistente"
  end
end
