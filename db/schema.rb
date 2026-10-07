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

ActiveRecord::Schema[8.1].define(version: 2026_10_07_130000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "unaccent"

  create_table "adelantos", force: :cascade do |t|
    t.bigint "orden_id", null: false
    t.decimal "importe", precision: 12, scale: 2, null: false
    t.datetime "registrado_en", null: false
    t.bigint "registrado_por_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["orden_id"], name: "index_adelantos_on_orden_id"
    t.index ["registrado_por_id"], name: "index_adelantos_on_registrado_por_id"
    t.check_constraint "importe > 0::numeric", name: "adelantos_importe_positivo"
  end

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
    t.text "motivo", null: false
    t.datetime "updated_at", null: false
    t.bigint "vehiculo_id", null: false
    t.datetime "cancelada_en"
    t.index ["cliente_id"], name: "index_ordenes_on_cliente_id"
    t.index ["vehiculo_id"], name: "index_ordenes_on_vehiculo_id"
    t.index ["vehiculo_id"], name: "index_ordenes_on_vehiculo_id_abierta", unique: true, where: "((estado)::text = 'abierta'::text)"
    t.check_constraint "(estado::text = 'cancelada'::text) = (cancelada_en IS NOT NULL)", name: "ordenes_cancelada_en_consistente"
  end

  create_table "repuestos", force: :cascade do |t|
    t.integer "cantidad", null: false
    t.decimal "costo_unitario", precision: 12, scale: 2
    t.datetime "created_at", null: false
    t.string "descripcion", null: false
    t.string "estado", default: "valorizado", null: false
    t.decimal "margen", precision: 5, scale: 2
    t.bigint "orden_id", null: false
    t.decimal "precio_cliente", precision: 24, scale: 2
    t.string "proveedor"
    t.bigint "registrado_por_id", null: false
    t.bigint "repuesto_catalogo_id"
    t.datetime "updated_at", null: false
    t.index ["orden_id"], name: "index_repuestos_on_orden_id"
    t.index ["registrado_por_id"], name: "index_repuestos_on_registrado_por_id"
    t.index ["repuesto_catalogo_id"], name: "index_repuestos_on_repuesto_catalogo_id"
    t.check_constraint "cantidad > 0", name: "repuestos_cantidad_positiva"
    t.check_constraint "costo_unitario >= 0::numeric", name: "repuestos_costo_no_negativo"
    t.check_constraint "estado::text <> 'valorizado'::text OR costo_unitario IS NOT NULL AND margen IS NOT NULL AND precio_cliente IS NOT NULL", name: "repuestos_valorizado_completo"
    t.check_constraint "margen >= 0::numeric AND margen <= 100::numeric", name: "repuestos_margen_valido"
  end

  create_table "repuestos_catalogo", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "nombre", null: false
    t.decimal "precio", precision: 12, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["nombre"], name: "index_repuestos_catalogo_on_nombre", unique: true
    t.check_constraint "precio >= 0::numeric", name: "catalogo_costo_no_negativo"
  end

  create_table "tareas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "descripcion", null: false
    t.string "estado", default: "pendiente", null: false
    t.bigint "mecanico_id"
    t.bigint "orden_id", null: false
    t.decimal "precio", precision: 10, scale: 2
    t.datetime "terminada_en"
    t.datetime "tomada_en"
    t.datetime "updated_at", null: false
    t.index ["mecanico_id"], name: "index_tareas_on_mecanico_id"
    t.index ["orden_id", "estado"], name: "index_tareas_on_orden_id_and_estado"
    t.index ["orden_id"], name: "index_tareas_on_orden_id"
  end

  create_table "tareas_frecuentes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "descripcion", null: false
    t.decimal "precio_sugerido", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index "lower((descripcion)::text)", name: "index_tareas_frecuentes_on_lower_descripcion", unique: true
  end

  create_table "usuarios", force: :cascade do |t|
    t.boolean "activo", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "nombre", null: false
    t.string "password_digest", null: false
    t.string "rol", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_usuarios_on_lower_email", unique: true
  end

  create_table "vehiculos", force: :cascade do |t|
    t.integer "anio"
    t.bigint "cliente_id", null: false
    t.datetime "created_at", null: false
    t.integer "kilometraje"
    t.string "marca"
    t.string "modelo"
    t.string "patente", null: false
    t.datetime "updated_at", null: false
    t.index ["cliente_id"], name: "index_vehiculos_on_cliente_id"
    t.index ["patente"], name: "index_vehiculos_on_patente", unique: true
    t.check_constraint "kilometraje >= 0", name: "vehiculos_kilometraje_no_negativo"
  end

  add_foreign_key "adelantos", "ordenes"
  add_foreign_key "adelantos", "usuarios", column: "registrado_por_id"
  add_foreign_key "ordenes", "clientes"
  add_foreign_key "ordenes", "vehiculos"
  add_foreign_key "repuestos", "ordenes"
  add_foreign_key "repuestos", "repuestos_catalogo", column: "repuesto_catalogo_id"
  add_foreign_key "repuestos", "usuarios", column: "registrado_por_id"
  add_foreign_key "tareas", "ordenes"
  add_foreign_key "tareas", "usuarios", column: "mecanico_id"
  add_foreign_key "vehiculos", "clientes"
end
