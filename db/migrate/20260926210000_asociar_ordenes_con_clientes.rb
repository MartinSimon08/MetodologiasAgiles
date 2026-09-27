class AsociarOrdenesConClientes < ActiveRecord::Migration[8.1]
  def change
    add_reference :ordenes, :cliente, null: false, foreign_key: true
    remove_column :ordenes, :cliente, :string
  end
end
