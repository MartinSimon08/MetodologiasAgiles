class AddPrecioToTareas < ActiveRecord::Migration[8.1]
  def change
    add_column :tareas, :precio, :decimal, precision: 10, scale: 2
  end
end
