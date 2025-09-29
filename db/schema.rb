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

ActiveRecord::Schema[8.0].define(version: 2025_09_23_180635) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "automations", force: :cascade do |t|
    t.bigint "template_id", null: false
    t.bigint "user_id", null: false
    t.string "status", default: "scheduled", null: false
    t.datetime "send_at", null: false
    t.boolean "enabled", default: true, null: false
    t.jsonb "action_data", null: false
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_automations_on_enabled"
    t.index ["send_at"], name: "index_automations_on_send_at"
    t.index ["status"], name: "index_automations_on_status"
    t.index ["template_id"], name: "index_automations_on_template_id"
    t.index ["user_id"], name: "index_automations_on_user_id"
  end

  create_table "templates", force: :cascade do |t|
    t.string "name", null: false
    t.string "spreadsheet_url"
    t.jsonb "rules_data", default: {}
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_templates_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.date "date_of_birth"
    t.string "major"
    t.string "classification"
    t.string "uin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["uin"], name: "index_users_on_uin", unique: true
  end

  add_foreign_key "automations", "templates"
  add_foreign_key "automations", "users"
  add_foreign_key "templates", "users"
end
