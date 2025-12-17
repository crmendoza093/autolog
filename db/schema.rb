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

ActiveRecord::Schema[8.0].define(version: 2025_12_17_010929) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "analytics_events", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_analytics_events_on_created_at"
    t.index ["event_type"], name: "index_analytics_events_on_event_type"
    t.index ["shop_id"], name: "index_analytics_events_on_shop_id"
  end

  create_table "clients", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "name", null: false
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "name"], name: "index_clients_on_shop_and_name"
    t.index ["shop_id", "name"], name: "index_clients_on_shop_id_and_name"
    t.index ["shop_id"], name: "index_clients_on_shop_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "state", default: "idle", null: false
    t.jsonb "payload", default: {}
    t.datetime "last_activity_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["last_activity_at"], name: "index_conversations_on_last_activity_at"
    t.index ["shop_id"], name: "index_conversations_on_shop_id"
    t.index ["state"], name: "index_conversations_on_state"
  end

  create_table "service_records", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.bigint "client_id"
    t.bigint "vehicle_id"
    t.string "service_name", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.text "notes"
    t.datetime "service_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_service_records_on_client_id"
    t.index ["created_at"], name: "index_service_records_on_created_at"
    t.index ["shop_id", "service_date"], name: "index_service_records_on_shop_and_date"
    t.index ["shop_id", "service_date"], name: "index_service_records_on_shop_id_and_service_date"
    t.index ["shop_id"], name: "index_service_records_on_shop_id"
    t.index ["vehicle_id"], name: "index_service_records_on_vehicle_id"
  end

  create_table "services", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "usage_count", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "active"], name: "index_services_on_shop_id_and_active"
    t.index ["shop_id", "name"], name: "index_services_on_shop_and_name"
    t.index ["shop_id", "name"], name: "index_services_on_shop_and_name_unique", unique: true
    t.index ["shop_id"], name: "index_services_on_shop_id"
    t.index ["usage_count"], name: "index_services_on_usage_count"
  end

  create_table "shops", force: :cascade do |t|
    t.string "name", null: false
    t.string "pin_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_shops_on_name", unique: true
  end

  create_table "vehicles", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.string "plate", null: false
    t.string "brand"
    t.string "color"
    t.string "model"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_vehicles_on_client_id"
    t.index ["plate", "client_id"], name: "index_vehicles_on_plate_and_client_id", unique: true
  end

  add_foreign_key "analytics_events", "shops"
  add_foreign_key "clients", "shops"
  add_foreign_key "conversations", "shops"
  add_foreign_key "service_records", "clients"
  add_foreign_key "service_records", "shops"
  add_foreign_key "service_records", "vehicles"
  add_foreign_key "services", "shops"
  add_foreign_key "vehicles", "clients"
end
