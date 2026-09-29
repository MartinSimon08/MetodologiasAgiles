class AddActivoToUsuarios < ActiveRecord::Migration[8.1]
  def change
    add_column :usuarios, :activo, :boolean, default: true, null: false
  end
end
