class CreateAseguradoras < ActiveRecord::Migration[8.1]
  def change
    create_table :aseguradoras do |t|
      t.string :nombre, null: false
      t.string :telefono
      t.string :email
      t.boolean :activa, default: true, null: false

      t.timestamps
    end

    add_index :aseguradoras, "lower(nombre)", unique: true, name: "index_aseguradoras_on_lower_nombre"
  end
end
