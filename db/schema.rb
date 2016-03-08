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

ActiveRecord::Schema.define(:version => 20160308215913) do

  create_table "access_conditions", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "active_admin_comments", :force => true do |t|
    t.integer  "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "agent_roles", :force => true do |t|
    t.string "name", :null => false
  end

  create_table "collection_admins", :force => true do |t|
    t.integer "collection_id", :null => false
    t.integer "user_id",       :null => false
  end

  add_index "collection_admins", ["collection_id", "user_id"], :name => "index_collection_admins_on_collection_id_and_user_id", :unique => true
  add_index "collection_admins", ["collection_id"], :name => "index_collection_admins_on_collection_id"
  add_index "collection_admins", ["user_id"], :name => "index_collection_admins_on_user_id"

  create_table "collection_countries", :force => true do |t|
    t.integer "collection_id"
    t.integer "country_id"
  end

  add_index "collection_countries", ["collection_id", "country_id"], :name => "index_collection_countries_on_collection_id_and_country_id", :unique => true

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
    t.integer  "operator_id"
    t.integer  "university_id"
    t.integer  "field_of_research_id"
    t.string   "region"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
    t.integer  "access_condition_id"
    t.text     "access_narrative"
    t.string   "metadata_source"
    t.string   "orthographic_notes"
    t.string   "media"
    t.text     "comments"
    t.boolean  "complete"
    t.boolean  "private"
    t.string   "tape_location"
    t.boolean  "deposit_form_received"
    t.float    "north_limit"
    t.float    "south_limit"
    t.float    "west_limit"
    t.float    "east_limit"
    t.string   "doi"
  end

  add_index "collections", ["access_condition_id"], :name => "index_collections_on_access_condition_id"
  add_index "collections", ["collector_id"], :name => "index_collections_on_collector_id"
  add_index "collections", ["field_of_research_id"], :name => "index_collections_on_field_of_research_id"
  add_index "collections", ["identifier"], :name => "index_collections_on_identifier", :unique => true
  add_index "collections", ["operator_id"], :name => "index_collections_on_operator_id"
  add_index "collections", ["university_id"], :name => "index_collections_on_university_id"

  create_table "collections_funding_bodies", :id => false, :force => true do |t|
    t.integer "collection_id",   :null => false
    t.integer "funding_body_id", :null => false
  end

  add_index "collections_funding_bodies", ["collection_id", "funding_body_id"], :name => "lookup_by_collection_and_funding_body_index"

  create_table "comments", :force => true do |t|
    t.integer  "owner_id",         :null => false
    t.integer  "commentable_id",   :null => false
    t.string   "commentable_type", :null => false
    t.text     "body",             :null => false
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.string   "status"
  end

  add_index "comments", ["commentable_id", "commentable_type"], :name => "index_comments_on_commentable_id_and_commentable_type"
  add_index "comments", ["owner_id"], :name => "index_comments_on_owner_id"

  create_table "countries", :force => true do |t|
    t.string "code"
    t.string "name"
  end

  add_index "countries", ["code"], :name => "index_countries_on_code", :unique => true
  add_index "countries", ["name"], :name => "index_countries_on_name", :unique => true

  create_table "countries_languages", :force => true do |t|
    t.integer "country_id",  :null => false
    t.integer "language_id", :null => false
  end

  add_index "countries_languages", ["country_id", "language_id"], :name => "index_countries_languages_on_country_id_and_language_id", :unique => true

  create_table "data_categories", :force => true do |t|
    t.string "name"
  end

  add_index "data_categories", ["name"], :name => "index_data_categories_on_name", :unique => true

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0, :null => false
    t.integer  "attempts",   :default => 0, :null => false
    t.text     "handler",                   :null => false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "discourse_types", :force => true do |t|
    t.string "name", :null => false
  end

  add_index "discourse_types", ["name"], :name => "index_discourse_types_on_name", :unique => true

  create_table "downloads", :force => true do |t|
    t.integer  "user_id"
    t.integer  "essence_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "downloads", ["essence_id"], :name => "index_downloads_on_essence_id"
  add_index "downloads", ["user_id"], :name => "index_downloads_on_user_id"

  create_table "essences", :force => true do |t|
    t.integer  "item_id"
    t.string   "filename"
    t.string   "mimetype"
    t.integer  "bitrate"
    t.integer  "samplerate"
    t.integer  "size",                    :limit => 8
    t.float    "duration"
    t.integer  "channels"
    t.integer  "fps"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "doi"
    t.boolean  "derived_files_generated",              :default => false
  end

  add_index "essences", ["item_id"], :name => "index_essences_on_item_id"

  create_table "fields_of_research", :force => true do |t|
    t.string "identifier"
    t.string "name"
  end

  add_index "fields_of_research", ["identifier"], :name => "index_fields_of_research_on_identifier", :unique => true
  add_index "fields_of_research", ["name"], :name => "index_fields_of_research_on_name", :unique => true

  create_table "funding_bodies", :force => true do |t|
    t.string   "name",       :null => false
    t.string   "key_prefix"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "grants", :force => true do |t|
    t.integer "collection_id"
    t.string  "grant_identifier"
    t.integer "funding_body_id"
  end

  add_index "grants", ["collection_id", "funding_body_id"], :name => "index_grants_on_collection_id_and_funding_body_id"
  add_index "grants", ["collection_id"], :name => "index_grants_on_collection_id"
  add_index "grants", ["funding_body_id"], :name => "index_grants_on_funding_body_id"

  create_table "item_admins", :force => true do |t|
    t.integer "item_id", :null => false
    t.integer "user_id", :null => false
  end

  add_index "item_admins", ["item_id", "user_id"], :name => "index_item_admins_on_item_id_and_user_id", :unique => true

  create_table "item_agents", :force => true do |t|
    t.integer "item_id",       :null => false
    t.integer "user_id",       :null => false
    t.integer "agent_role_id", :null => false
  end

  add_index "item_agents", ["item_id", "user_id", "agent_role_id"], :name => "index_item_agents_on_item_id_and_user_id_and_agent_role_id", :unique => true

  create_table "item_content_languages", :force => true do |t|
    t.integer "item_id",     :null => false
    t.integer "language_id", :null => false
  end

  add_index "item_content_languages", ["item_id", "language_id"], :name => "index_item_content_languages_on_item_id_and_language_id", :unique => true

  create_table "item_countries", :force => true do |t|
    t.integer "item_id",    :null => false
    t.integer "country_id", :null => false
  end

  add_index "item_countries", ["item_id", "country_id"], :name => "index_item_countries_on_item_id_and_country_id", :unique => true

  create_table "item_data_categories", :force => true do |t|
    t.integer "item_id",          :null => false
    t.integer "data_category_id", :null => false
  end

  add_index "item_data_categories", ["item_id", "data_category_id"], :name => "index_item_data_categories_on_item_id_and_data_category_id", :unique => true

  create_table "item_subject_languages", :force => true do |t|
    t.integer "item_id",     :null => false
    t.integer "language_id", :null => false
  end

  add_index "item_subject_languages", ["item_id", "language_id"], :name => "index_item_subject_languages_on_item_id_and_language_id", :unique => true

  create_table "item_users", :force => true do |t|
    t.integer "item_id", :null => false
    t.integer "user_id", :null => false
  end

  add_index "item_users", ["item_id", "user_id"], :name => "index_item_users_on_item_id_and_user_id", :unique => true

  create_table "items", :force => true do |t|
    t.integer  "collection_id",                              :null => false
    t.string   "identifier",                                 :null => false
    t.boolean  "private"
    t.string   "title",                                      :null => false
    t.string   "url"
    t.integer  "collector_id",                               :null => false
    t.integer  "university_id"
    t.integer  "operator_id"
    t.text     "description",                                :null => false
    t.date     "originated_on"
    t.string   "language"
    t.string   "dialect"
    t.string   "region"
    t.integer  "discourse_type_id"
    t.integer  "access_condition_id"
    t.text     "access_narrative"
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
    t.boolean  "metadata_exportable"
    t.boolean  "born_digital"
    t.boolean  "tapes_returned"
    t.text     "original_media"
    t.datetime "received_on"
    t.datetime "digitised_on"
    t.text     "ingest_notes"
    t.datetime "metadata_imported_on"
    t.datetime "metadata_exported_on"
    t.text     "tracking"
    t.text     "admin_comment"
    t.boolean  "external",                :default => false
    t.text     "originated_on_narrative"
    t.float    "north_limit"
    t.float    "south_limit"
    t.float    "west_limit"
    t.float    "east_limit"
    t.string   "doi"
  end

  add_index "items", ["access_condition_id"], :name => "index_items_on_access_condition_id"
  add_index "items", ["collection_id"], :name => "index_items_on_collection_id"
  add_index "items", ["collector_id"], :name => "index_items_on_collector_id"
  add_index "items", ["discourse_type_id"], :name => "index_items_on_discourse_type_id"
  add_index "items", ["identifier", "collection_id"], :name => "index_items_on_identifier_and_collection_id", :unique => true
  add_index "items", ["operator_id"], :name => "index_items_on_operator_id"
  add_index "items", ["university_id"], :name => "index_items_on_university_id"

  create_table "languages", :force => true do |t|
    t.string  "code"
    t.string  "name"
    t.boolean "retired"
    t.float   "north_limit"
    t.float   "south_limit"
    t.float   "west_limit"
    t.float   "east_limit"
  end

  add_index "languages", ["code"], :name => "index_languages_on_code", :unique => true

  create_table "latlon_boundaries", :force => true do |t|
    t.integer "country_id",                                                   :null => false
    t.decimal "east_limit",  :precision => 6, :scale => 3,                    :null => false
    t.decimal "west_limit",  :precision => 6, :scale => 3,                    :null => false
    t.decimal "north_limit", :precision => 6, :scale => 3,                    :null => false
    t.decimal "south_limit", :precision => 6, :scale => 3,                    :null => false
    t.boolean "wrapped",                                   :default => false
  end

  add_index "latlon_boundaries", ["country_id"], :name => "index_latlon_boundaries_on_country_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "universities", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.string   "party_identifier"
  end

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "encrypted_password",       :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",            :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "password_salt"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",          :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "first_name",                                  :null => false
    t.string   "last_name"
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.boolean  "admin",                    :default => false, :null => false
    t.string   "address"
    t.string   "address2"
    t.string   "country"
    t.string   "phone"
    t.boolean  "contact_only",             :default => false
    t.integer  "rights_transferred_to_id"
    t.string   "rights_transfer_reason"
    t.string   "party_identifier"
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["rights_transferred_to_id"], :name => "index_users_on_rights_transferred_to_id"
  add_index "users", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true

  create_table "versions", :force => true do |t|
    t.string   "item_type",      :null => false
    t.integer  "item_id",        :null => false
    t.string   "event",          :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.text     "object_changes"
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"

end
