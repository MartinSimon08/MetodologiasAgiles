class AgregarCierreAOrdenes < ActiveRecord::Migration[8.1]
  def change
    add_column :ordenes, :cerrada_en, :datetime
    add_reference :ordenes, :cerrada_por, foreign_key: { to_table: :usuarios }
    add_column :ordenes, :total_cerrado, :decimal, precision: 24, scale: 2
    add_check_constraint :ordenes,
                         "(estado = 'cerrada') = (cerrada_en IS NOT NULL AND cerrada_por_id IS NOT NULL AND total_cerrado IS NOT NULL)",
                         name: "ordenes_cierre_consistente"
  end
end
