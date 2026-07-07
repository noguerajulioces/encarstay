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

ActiveRecord::Schema[8.1].define(version: 2026_07_07_184220) do
  create_table "blocks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "ends_on", null: false
    t.integer "property_id", null: false
    t.string "reason"
    t.date "starts_on", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id", "starts_on", "ends_on"], name: "index_blocks_on_property_id_and_starts_on_and_ends_on"
    t.index ["property_id"], name: "index_blocks_on_property_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.datetime "cancelled_at"
    t.date "check_in", null: false
    t.date "check_out", null: false
    t.integer "cleaning_fee_cents", default: 0, null: false
    t.string "code", null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "currency", default: "PYG", null: false
    t.string "guest_email", null: false
    t.string "guest_name", null: false
    t.string "guest_phone"
    t.integer "guests_count", default: 1, null: false
    t.text "notes"
    t.integer "property_id", null: false
    t.string "source", default: "direct", null: false
    t.string "status", default: "pending", null: false
    t.integer "subtotal_cents", default: 0, null: false
    t.integer "total_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_bookings_on_code", unique: true
    t.index ["property_id", "status", "check_in", "check_out"], name: "idx_on_property_id_status_check_in_check_out_e998aafd96"
    t.index ["property_id"], name: "index_bookings_on_property_id"
  end

  create_table "calendar_sources", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "ical_url", null: false
    t.string "last_status"
    t.datetime "last_synced_at"
    t.string "name", default: "Airbnb", null: false
    t.integer "property_id", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_calendar_sources_on_property_id"
  end

  create_table "external_events", force: :cascade do |t|
    t.integer "calendar_source_id", null: false
    t.datetime "created_at", null: false
    t.date "ends_on", null: false
    t.text "raw_payload"
    t.date "starts_on", null: false
    t.string "summary"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["calendar_source_id", "starts_on", "ends_on"], name: "idx_on_calendar_source_id_starts_on_ends_on_cbd0cf827a"
    t.index ["calendar_source_id", "uid"], name: "index_external_events_on_calendar_source_id_and_uid", unique: true
    t.index ["calendar_source_id"], name: "index_external_events_on_calendar_source_id"
  end

  create_table "photos", force: :cascade do |t|
    t.string "caption"
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.integer "property_id", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_photos_on_property_id"
  end

  create_table "properties", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "address_area"
    t.integer "base_price_cents", default: 0, null: false
    t.integer "bathrooms", default: 1, null: false
    t.integer "bedrooms", default: 1, null: false
    t.integer "beds", default: 1, null: false
    t.string "calendar_token", null: false
    t.integer "capacity", default: 2, null: false
    t.integer "cleaning_fee_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "PYG", null: false
    t.text "description"
    t.integer "min_nights", default: 2, null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["calendar_token"], name: "index_properties_on_calendar_token", unique: true
    t.index ["slug"], name: "index_properties_on_slug", unique: true
  end

  create_table "seasonal_rates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "ends_on", null: false
    t.integer "min_nights"
    t.string "name", null: false
    t.integer "price_per_night_cents", default: 0, null: false
    t.integer "property_id", null: false
    t.date "starts_on", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id", "starts_on", "ends_on"], name: "index_seasonal_rates_on_property_id_and_starts_on_and_ends_on"
    t.index ["property_id"], name: "index_seasonal_rates_on_property_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "blocks", "properties"
  add_foreign_key "bookings", "properties"
  add_foreign_key "calendar_sources", "properties"
  add_foreign_key "external_events", "calendar_sources"
  add_foreign_key "photos", "properties"
  add_foreign_key "seasonal_rates", "properties"
end
