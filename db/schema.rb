# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_27_113000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "clientes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "nombre", null: false
    t.string "telefono", null: false
    t.datetime "updated_at", null: false
    t.index ["telefono"], name: "index_clientes_on_telefono", unique: true
  end

  create_table "configuraciones_taller", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "margen_repuestos", precision: 5, scale: 2, default: "0.0", null: false
    t.boolean "registro_unico", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["registro_unico"], name: "index_configuraciones_taller_on_registro_unico", unique: true
    t.check_constraint "margen_repuestos >= 0::numeric AND margen_repuestos <= 100::numeric", name: "configuraciones_taller_margen_repuestos_valido"
    t.check_constraint "registro_unico = true", name: "configuraciones_taller_registro_unico"
  end

  create_table "ordenes", force: :cascade do |t|
    t.bigint "cliente_id", null: false
    t.datetime "created_at", null: false
    t.string "estado", default: "abierta", null: false
    t.datetime "updated_at", null: false
    t.string "vehiculo", null: false
    t.index ["cliente_id"], name: "index_ordenes_on_cliente_id"
  end

  create_table "tareas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "descripcion", null: false
    t.string "estado", default: "pendiente", null: false
    t.bigint "mecanico_id"
    t.bigint "orden_id", null: false
    t.datetime "terminada_en"
    t.datetime "tomada_en"
    t.datetime "updated_at", null: false
    t.index ["mecanico_id"], name: "index_tareas_on_mecanico_id"
    t.index ["orden_id", "estado"], name: "index_tareas_on_orden_id_and_estado"
    t.index ["orden_id"], name: "index_tareas_on_orden_id"
  end

  create_table "usuarios", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "nombre", null: false
    t.string "password_digest", null: false
    t.string "rol", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_usuarios_on_lower_email", unique: true
  end

  add_foreign_key "ordenes", "clientes"
  add_foreign_key "tareas", "ordenes"
  add_foreign_key "tareas", "usuarios", column: "mecanico_id"
end
