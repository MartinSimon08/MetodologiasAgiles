class AgregarAprobacionATareas < ActiveRecord::Migration[8.1]
  def change
    add_column :tareas, :aprobacion, :string, null: false, default: "pendiente"
  end
end
