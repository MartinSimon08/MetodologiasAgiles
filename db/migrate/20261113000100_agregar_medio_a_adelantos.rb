class AgregarMedioAAdelantos < ActiveRecord::Migration[8.1]
  def change
    add_column :adelantos, :medio, :string, null: false, default: "efectivo"

    add_check_constraint :adelantos,
                         "medio IN ('efectivo', 'transferencia', 'tarjeta')",
                         name: "adelantos_medio_valido"
  end
end
