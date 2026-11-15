class CreateNotificacionAsegurados < ActiveRecord::Migration[8.1]
  def change
    create_table :notificacion_asegurados do |t|
      t.references :caso, null: false, foreign_key: true
      t.string :medio, null: false
      t.text :contenido, null: false
      t.datetime :enviada_en, null: false

      t.timestamps
    end
  end
end
