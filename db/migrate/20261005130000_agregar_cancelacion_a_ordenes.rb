class AgregarCancelacionAOrdenes < ActiveRecord::Migration[8.1]
  def change
    add_column :ordenes, :cancelada_en, :datetime
    add_check_constraint :ordenes, "(estado = 'cancelada') = (cancelada_en IS NOT NULL)",
                         name: "ordenes_cancelada_en_consistente"
  end
end
