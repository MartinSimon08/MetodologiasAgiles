class CreateClientes < ActiveRecord::Migration[8.1]
  def change
    create_table :clientes do |t|
      t.string :nombre, null: false
      t.string :telefono, null: false, index: { unique: true }
      t.string :email

      t.timestamps
    end
  end
end
