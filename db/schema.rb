# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111115013030) do

  create_table "collection_countries", :force => true do |t|
    t.integer "collection_id"
    t.integer "country_id"
  end

  add_index "collection_countries", ["collection_id", "country_id"], :name => "index_collection_countries_on_collection_id_and_country_id", :unique => true

  create_table "collection_fields_of_research", :force => true do |t|
    t.integer "collection_id"
    t.integer "field_of_research_id"
  end

  add_index "collection_fields_of_research", ["collection_id", "field_of_research_id"], :name => "collection_fields_of_research_idx", :unique => true

  create_table "collection_languages", :force => true do |t|
    t.integer "collection_id"
    t.integer "language_id"
  end

  add_index "collection_languages", ["collection_id", "language_id"], :name => "index_collection_languages_on_collection_id_and_language_id", :unique => true

  create_table "collections", :force => true do |t|
    t.string   "identifier",            :null => false
    t.string   "title",                 :null => false
    t.text     "description",           :null => false
    t.integer  "collector_id",          :null => false
    t.integer  "university_id"
    t.integer  "field_of_research_id",  :null => false
    t.string   "region"
    t.float    "latitude"
    t.float    "longitude"
    t.integer  "zoom"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "collections", ["collector_id"], :name => "index_collections_on_collector_id"
  add_index "collections", ["field_of_research_id"], :name => "index_collections_on_field_of_research_id"
  add_index "collections", ["identifier"], :name => "index_collections_on_identifier", :unique => true
  add_index "collections", ["university_id"], :name => "index_collections_on_university_id"

  create_table "countries", :force => true do |t|
    t.string "name"
  end

  add_index "countries", ["name"], :name => "index_countries_on_name", :unique => true

  create_table "fields_of_research", :force => true do |t|
    t.string "identifier"
    t.string "name"
  end

  add_index "fields_of_research", ["identifier"], :name => "index_fields_of_research_on_identifier", :unique => true
  add_index "fields_of_research", ["name"], :name => "index_fields_of_research_on_name", :unique => true

  create_table "languages", :force => true do |t|
    t.string "code"
    t.string "name"
  end

  create_table "universities", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                 :default => "",    :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",                       :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "first_name",                                               :null => false
    t.string   "last_name",                                                :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "admin",                                 :default => false, :null => false
    t.string   "address"
    t.string   "country"
    t.string   "phone"
    t.boolean  "operator",                              :default => false
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true

end
