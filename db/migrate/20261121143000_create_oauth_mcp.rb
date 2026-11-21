class CreateOauthMcp < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_clientes do |t|
      t.text :client_id, null: false
      t.string :nombre, null: false
      t.text :redirect_uris, array: true, null: false, default: []
      t.string :origen, null: false
      t.datetime :metadata_expira_en

      t.timestamps
    end
    add_index :oauth_clientes, :client_id, unique: true
    add_check_constraint :oauth_clientes, "origen IN ('registro', 'metadata')", name: "oauth_clientes_origen_valido"
    add_check_constraint :oauth_clientes, "cardinality(redirect_uris) > 0", name: "oauth_clientes_redirects_presentes"

    create_table :oauth_codigos do |t|
      t.string :digesto, null: false
      t.references :usuario, null: false, foreign_key: true
      t.text :client_id, null: false
      t.text :redirect_uri, null: false
      t.string :code_challenge, null: false
      t.text :recurso, null: false
      t.string :scope, null: false
      t.datetime :expira_en, null: false
      t.datetime :usado_en

      t.timestamps
    end
    add_index :oauth_codigos, :digesto, unique: true

    create_table :oauth_refresh_tokens do |t|
      t.string :digesto, null: false
      t.string :familia, null: false
      t.references :usuario, null: false, foreign_key: true
      t.text :client_id, null: false
      t.text :recurso, null: false
      t.string :scope, null: false
      t.datetime :expira_en, null: false
      t.datetime :reemplazado_en
      t.datetime :revocado_en

      t.timestamps
    end
    add_index :oauth_refresh_tokens, :digesto, unique: true
    add_index :oauth_refresh_tokens, :familia
  end
end
