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

ActiveRecord::Schema[7.1].define(version: 2025_07_25_081912) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "daily_sleep_summaries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date"
    t.integer "total_sleep_duration_minutes"
    t.integer "number_of_sleep_sessions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "date"], name: "index_daily_sleep_summaries_on_user_id_and_date", unique: true
    t.index ["user_id", "total_sleep_duration_minutes", "date"], name: "index_daily_sleep_summaries_on_user_duration_date"
    t.index ["user_id"], name: "index_daily_sleep_summaries_on_user_id"
  end

  create_table "follows", force: :cascade do |t|
    t.bigint "follower_id"
    t.bigint "followed_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id"], name: "index_follows_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_follows_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
  end

  create_table "sleeps", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "clock_in_time"
    t.datetime "clock_out_time"
    t.integer "duration_minutes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["clock_in_time"], name: "index_sleep_records_on_clock_in_time"
    t.index ["clock_out_time"], name: "index_sleep_records_on_clock_out_time"
    t.index ["duration_minutes"], name: "index_sleep_records_on_duration_minutes_partial", order: :desc, where: "(clock_out_time IS NOT NULL)"
    t.index ["user_id", "clock_in_time", "duration_minutes"], name: "index_sleep_records_on_user_id_clock_in_duration_minutes"
    t.index ["user_id"], name: "index_sleep_records_on_user_id"
    t.index ["user_id"], name: "index_sleep_records_on_user_id_clock_out_time_null", unique: true, where: "(clock_out_time IS NULL)"
    t.index ["user_id"], name: "index_sleeps_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_users_on_name"
  end

  add_foreign_key "daily_sleep_summaries", "users"
  add_foreign_key "sleeps", "users"
end
