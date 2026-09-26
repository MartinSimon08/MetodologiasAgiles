class CreateUsuarios < ActiveRecord::Migration[8.1]
  def change
    create_table :usuarios do |t|
      t.string :nombre, null: false
      t.string :email, null: false
      t.string :rol, null: false
      t.string :password_digest, null: false

      t.timestamps
    end

    add_index :usuarios, "lower(email)", unique: true, name: "index_usuarios_on_lower_email"
  end
end
