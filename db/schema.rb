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

ActiveRecord::Schema[8.1].define(version: 2026_07_08_010347) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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
    t.string "locale", default: "es", null: false
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

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "icon"
    t.string "name_en"
    t.string "name_es"
    t.string "name_pt"
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_categories_on_slug", unique: true
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

  create_table "guide_entries", force: :cascade do |t|
    t.string "address"
    t.string "area"
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.text "description_en"
    t.text "description_es"
    t.text "description_pt"
    t.datetime "ends_at"
    t.string "external_url"
    t.boolean "featured", default: false, null: false
    t.string "kind", default: "attraction", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.integer "position", default: 0, null: false
    t.boolean "published", default: false, null: false
    t.boolean "recurring", default: false, null: false
    t.string "schedule_note_en"
    t.string "schedule_note_es"
    t.string "schedule_note_pt"
    t.string "slug", null: false
    t.datetime "starts_at"
    t.string "summary_en"
    t.string "summary_es"
    t.string "summary_pt"
    t.string "title_en"
    t.string "title_es"
    t.string "title_pt"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_guide_entries_on_category_id"
    t.index ["kind", "featured"], name: "index_guide_entries_on_kind_and_featured"
    t.index ["kind", "published"], name: "index_guide_entries_on_kind_and_published"
    t.index ["slug"], name: "index_guide_entries_on_slug", unique: true
    t.index ["starts_at"], name: "index_guide_entries_on_starts_at"
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
    t.string "airbnb_listing_url"
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

  create_table "property_recommendations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "guide_entry_id", null: false
    t.integer "position", default: 0, null: false
    t.integer "property_id", null: false
    t.datetime "updated_at", null: false
    t.index ["guide_entry_id", "property_id"], name: "idx_on_guide_entry_id_property_id_9e1aa032be", unique: true
    t.index ["guide_entry_id"], name: "index_property_recommendations_on_guide_entry_id"
    t.index ["property_id"], name: "index_property_recommendations_on_property_id"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "blocks", "properties"
  add_foreign_key "bookings", "properties"
  add_foreign_key "calendar_sources", "properties"
  add_foreign_key "external_events", "calendar_sources"
  add_foreign_key "guide_entries", "categories"
  add_foreign_key "photos", "properties"
  add_foreign_key "property_recommendations", "guide_entries"
  add_foreign_key "property_recommendations", "properties"
  add_foreign_key "seasonal_rates", "properties"
end
