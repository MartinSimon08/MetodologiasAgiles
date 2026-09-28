class IndependizarCatalogoRepuestos < ActiveRecord::Migration[8.1]
  def change
    rename_column :repuestos_catalogo, :ultimo_costo, :precio
    change_column_null :repuestos, :repuesto_catalogo_id, true
  end
end
