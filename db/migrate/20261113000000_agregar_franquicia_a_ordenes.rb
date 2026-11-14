class AgregarFranquiciaAOrdenes < ActiveRecord::Migration[8.1]
  def change
    add_column :ordenes, :franquicia, :decimal, precision: 24, scale: 2

    add_check_constraint :ordenes,
                         "franquicia IS NULL OR (franquicia >= 0 AND estado = 'cerrada' AND franquicia <= total_cerrado)",
                         name: "ordenes_franquicia_valida"
  end
end
