class AgregarAprobacionAItems < ActiveRecord::Migration[8.1]
  def change
    add_column :repuestos, :aprobacion, :string, null: false, default: "pendiente"
    add_check_constraint :repuestos,
                         "aprobacion IN ('pendiente', 'aprobado', 'rechazado')",
                         name: "repuestos_aprobacion_valida"
  end
end
