class AgregarCupoDiarioAConfiguracionesTaller < ActiveRecord::Migration[8.1]
  def change
    add_column :configuraciones_taller, :cupo_diario, :integer, null: false, default: 5
    add_check_constraint :configuraciones_taller, "cupo_diario > 0", name: "configuraciones_taller_cupo_diario_valido"
  end
end
