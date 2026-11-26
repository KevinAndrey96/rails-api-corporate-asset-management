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

ActiveRecord::Schema[8.1].define(version: 2026_11_26_080300) do
  create_table "api_clients", force: :cascade do |t|
    t.string "name", limit: 80, null: false
    t.string "token_digest", null: false
    t.integer "access", default: 0, null: false
    t.datetime "last_used_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_api_clients_on_name", unique: true
    t.index ["token_digest"], name: "index_api_clients_on_token_digest", unique: true
  end

  create_table "assets", force: :cascade do |t|
    t.string "tag", limit: 12, null: false
    t.integer "category", null: false
    t.integer "status", default: 0, null: false
    t.string "brand", limit: 60, null: false
    t.string "model", limit: 80, null: false
    t.string "serial_number", limit: 60
    t.date "purchased_on", null: false
    t.bigint "purchase_cost", null: false
    t.string "plate", limit: 6
    t.date "soat_expires_on"
    t.date "technical_review_expires_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category", "status"], name: "index_assets_on_category_and_status"
    t.index ["plate"], name: "index_assets_on_plate", unique: true
    t.index ["serial_number"], name: "index_assets_on_serial_number", unique: true
    t.index ["tag"], name: "index_assets_on_tag", unique: true
    t.check_constraint "purchase_cost > 0", name: "assets_purchase_cost_positive"
  end

  create_table "assignments", force: :cascade do |t|
    t.integer "asset_id", null: false
    t.integer "employee_id", null: false
    t.date "assigned_on", null: false
    t.date "due_on"
    t.date "returned_on"
    t.string "notes", limit: 500
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_assignments_on_asset_id"
    t.index ["asset_id"], name: "index_assignments_one_open_per_asset", unique: true, where: "returned_on IS NULL"
    t.index ["employee_id"], name: "index_assignments_on_employee_id"
    t.check_constraint "due_on IS NULL OR due_on >= assigned_on", name: "assignments_due_after_assigned"
    t.check_constraint "returned_on IS NULL OR returned_on >= assigned_on", name: "assignments_returned_after_assigned"
  end

  create_table "employees", force: :cascade do |t|
    t.string "document_number", limit: 10, null: false
    t.string "full_name", limit: 120, null: false
    t.string "email", null: false
    t.string "department", limit: 80, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["department"], name: "index_employees_on_department"
    t.index ["document_number"], name: "index_employees_on_document_number", unique: true
    t.index ["email"], name: "index_employees_on_email", unique: true
  end

  add_foreign_key "assignments", "assets"
  add_foreign_key "assignments", "employees"
end
