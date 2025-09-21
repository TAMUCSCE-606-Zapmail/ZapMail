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

ActiveRecord::Schema[8.0].define(version: 2025_09_21_015320) do
  create_table "automation_histories", force: :cascade do |t|
    t.integer "automation_id", null: false
    t.json "row_data"
    t.string "email_status"
    t.text "api_response"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["automation_id"], name: "index_automation_histories_on_automation_id"
  end

  create_table "automations", force: :cascade do |t|
    t.integer "strategy_id", null: false
    t.string "status"
    t.datetime "next_run_time"
    t.string "schedule_type"
    t.datetime "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["strategy_id"], name: "index_automations_on_strategy_id"
  end

  create_table "conditions", force: :cascade do |t|
    t.integer "rule_id", null: false
    t.string "column_name"
    t.string "operator"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rule_id"], name: "index_conditions_on_rule_id"
  end

  create_table "rules", force: :cascade do |t|
    t.integer "strategy_id", null: false
    t.integer "order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["strategy_id"], name: "index_rules_on_strategy_id"
  end

  create_table "strategies", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name"
    t.string "csv_file_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_strategies_on_user_id"
  end

  create_table "strategy_actions", force: :cascade do |t|
    t.integer "rule_id", null: false
    t.string "action_type"
    t.text "prompt_template"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rule_id"], name: "index_strategy_actions_on_rule_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "automation_histories", "automations"
  add_foreign_key "automations", "strategies"
  add_foreign_key "conditions", "rules"
  add_foreign_key "rules", "strategies"
  add_foreign_key "strategies", "users"
  add_foreign_key "strategy_actions", "rules"
end
