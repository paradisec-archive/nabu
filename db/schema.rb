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

ActiveRecord::Schema[8.0].define(version: 2024_12_02_233312) do
  create_table "access_conditions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "active_admin_comments", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "resource_id", null: false
    t.string "resource_type", null: false
    t.integer "author_id"
    t.string "author_type"
    t.text "body", size: :medium
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "namespace"
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_admin_notes_on_resource_type_and_resource_id"
  end

  create_table "admin_messages", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "message", size: :medium, null: false
    t.datetime "start_at", precision: nil, null: false
    t.datetime "finish_at", precision: nil, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "agent_roles", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "collection_admins", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "collection_id", null: false
    t.integer "user_id", null: false
    t.index ["collection_id", "user_id"], name: "index_collection_admins_on_collection_id_and_user_id", unique: true
    t.index ["collection_id"], name: "index_collection_admins_on_collection_id"
    t.index ["user_id"], name: "index_collection_admins_on_user_id"
  end

  create_table "collection_countries", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "collection_id"
    t.integer "country_id"
    t.index ["collection_id", "country_id"], name: "index_collection_countries_on_collection_id_and_country_id", unique: true
  end

  create_table "collection_languages", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "collection_id"
    t.integer "language_id"
    t.index ["collection_id", "language_id"], name: "index_collection_languages_on_collection_id_and_language_id", unique: true
  end

  create_table "collections", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "identifier", null: false, collation: "utf8mb4_bin"
    t.string "title", null: false
    t.text "description", size: :medium, null: false
    t.integer "collector_id", null: false
    t.integer "operator_id"
    t.integer "university_id"
    t.integer "field_of_research_id"
    t.string "region"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "access_condition_id"
    t.text "access_narrative", size: :medium
    t.string "metadata_source"
    t.string "orthographic_notes"
    t.string "media"
    t.text "comments", size: :medium
    t.boolean "complete"
    t.boolean "private"
    t.string "tape_location"
    t.boolean "deposit_form_received"
    t.float "north_limit"
    t.float "south_limit"
    t.float "west_limit"
    t.float "east_limit"
    t.string "doi"
    t.boolean "has_deposit_form"
    t.index ["access_condition_id"], name: "index_collections_on_access_condition_id"
    t.index ["collector_id"], name: "index_collections_on_collector_id"
    t.index ["field_of_research_id"], name: "index_collections_on_field_of_research_id"
    t.index ["identifier"], name: "index_collections_on_identifier", unique: true
    t.index ["operator_id"], name: "index_collections_on_operator_id"
    t.index ["private"], name: "index_collections_on_private"
    t.index ["university_id"], name: "index_collections_on_university_id"
  end

  create_table "collections_funding_bodies", id: false, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "collection_id", null: false
    t.integer "funding_body_id", null: false
    t.index ["collection_id", "funding_body_id"], name: "lookup_by_collection_and_funding_body_index"
  end

  create_table "comments", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "owner_id", null: false
    t.integer "commentable_id", null: false
    t.string "commentable_type", null: false
    t.text "body", size: :medium, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "status"
    t.index ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type"
    t.index ["owner_id"], name: "index_comments_on_owner_id"
  end

  create_table "countries", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.index ["code"], name: "index_countries_on_code", unique: true
    t.index ["name"], name: "index_countries_on_name", unique: true
  end

  create_table "countries_languages", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "country_id", null: false
    t.integer "language_id", null: false
    t.index ["country_id", "language_id"], name: "index_countries_languages_on_country_id_and_language_id", unique: true
  end

  create_table "data_categories", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.index ["name"], name: "index_data_categories_on_name", unique: true
  end

  create_table "data_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "discourse_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.index ["name"], name: "index_discourse_types_on_name", unique: true
  end

  create_table "downloads", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "essence_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["essence_id"], name: "index_downloads_on_essence_id"
    t.index ["user_id"], name: "index_downloads_on_user_id"
  end

  create_table "dump_for_nick", id: false, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "collid", null: false
    t.string "itemid", null: false
    t.text "subject_languages", size: :long
    t.text "content_languages", size: :long
  end

  create_table "essences", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "item_id"
    t.string "filename"
    t.string "mimetype"
    t.integer "bitrate"
    t.integer "samplerate"
    t.bigint "size"
    t.float "duration"
    t.integer "channels"
    t.integer "fps"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "doi"
    t.boolean "derived_files_generated", default: false
    t.index ["item_id", "filename"], name: "index_essences_on_item_id_and_filename", unique: true
    t.index ["item_id"], name: "index_essences_on_item_id"
  end

  create_table "fields_of_research", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "identifier"
    t.string "name"
    t.index ["identifier"], name: "index_fields_of_research_on_identifier", unique: true
    t.index ["name"], name: "index_fields_of_research_on_name", unique: true
  end

  create_table "funding_bodies", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "key_prefix"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "grants", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "collection_id"
    t.string "grant_identifier"
    t.integer "funding_body_id"
    t.index ["collection_id", "funding_body_id"], name: "index_grants_on_collection_id_and_funding_body_id"
    t.index ["collection_id"], name: "index_grants_on_collection_id"
    t.index ["funding_body_id"], name: "index_grants_on_funding_body_id"
  end

  create_table "item_admins", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "item_id", null: false
    t.integer "user_id", null: false
    t.index ["item_id", "user_id"], name: "index_item_admins_on_item_id_and_user_id", unique: true
  end

  create_table "item_agents", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "item_id", null: false
    t.integer "user_id", null: false
    t.integer "agent_role_id", null: false
    t.index ["item_id", "user_id", "agent_role_id"], name: "index_item_agents_on_item_id_and_user_id_and_agent_role_id", unique: true
  end

  create_table "item_content_languages", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "item_id", null: false
    t.integer "language_id", null: false
    t.index ["item_id", "language_id"], name: "index_item_content_languages_on_item_id_and_language_id", unique: true
  end

  create_table "item_countries", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "item_id", null: false
    t.integer "country_id", null: false
    t.index ["item_id", "country_id"], name: "index_item_countries_on_item_id_and_country_id", unique: true
  end

  create_table "item_data_categories", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "item_id", null: false
    t.integer "data_category_id", null: false
    t.index ["item_id", "data_category_id"], name: "index_item_data_categories_on_item_id_and_data_category_id", unique: true
  end

  create_table "item_data_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "item_id", null: false
    t.integer "data_type_id", null: false
    t.index ["data_type_id"], name: "index_item_data_types_on_data_type_id"
    t.index ["item_id"], name: "index_item_data_types_on_item_id"
  end

  create_table "item_subject_languages", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "item_id", null: false
    t.integer "language_id", null: false
    t.index ["item_id", "language_id"], name: "index_item_subject_languages_on_item_id_and_language_id", unique: true
  end

  create_table "item_users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "item_id", null: false
    t.integer "user_id", null: false
    t.index ["item_id", "user_id"], name: "index_item_users_on_item_id_and_user_id", unique: true
  end

  create_table "items", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "collection_id", null: false
    t.string "identifier", null: false, collation: "utf8mb4_bin"
    t.boolean "private"
    t.string "title", null: false
    t.string "url"
    t.integer "collector_id", null: false
    t.integer "university_id"
    t.integer "operator_id"
    t.text "description", size: :medium, null: false
    t.date "originated_on"
    t.string "language"
    t.string "dialect"
    t.string "region"
    t.integer "discourse_type_id"
    t.integer "access_condition_id"
    t.text "access_narrative", size: :medium
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "metadata_exportable"
    t.boolean "born_digital"
    t.boolean "tapes_returned"
    t.text "original_media", size: :medium
    t.datetime "received_on", precision: nil
    t.datetime "digitised_on", precision: nil
    t.text "ingest_notes", size: :medium
    t.datetime "metadata_imported_on", precision: nil
    t.datetime "metadata_exported_on", precision: nil
    t.text "tracking", size: :medium
    t.text "admin_comment", size: :medium
    t.boolean "external", default: false
    t.text "originated_on_narrative", size: :medium
    t.float "north_limit"
    t.float "south_limit"
    t.float "west_limit"
    t.float "east_limit"
    t.string "doi"
    t.integer "essences_count"
    t.index ["access_condition_id"], name: "index_items_on_access_condition_id"
    t.index ["collection_id", "private", "updated_at"], name: "index_items_on_collection_id_and_private_and_updated_at"
    t.index ["collection_id"], name: "index_items_on_collection_id"
    t.index ["collector_id"], name: "index_items_on_collector_id"
    t.index ["discourse_type_id"], name: "index_items_on_discourse_type_id"
    t.index ["identifier", "collection_id"], name: "index_items_on_identifier_and_collection_id", unique: true
    t.index ["operator_id"], name: "index_items_on_operator_id"
    t.index ["university_id"], name: "index_items_on_university_id"
  end

  create_table "languages", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.boolean "retired"
    t.float "north_limit"
    t.float "south_limit"
    t.float "west_limit"
    t.float "east_limit"
    t.index ["code"], name: "index_languages_on_code", unique: true
  end

  create_table "latlon_boundaries", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "country_id", null: false
    t.decimal "east_limit", precision: 6, scale: 3, null: false
    t.decimal "west_limit", precision: 6, scale: 3, null: false
    t.decimal "north_limit", precision: 6, scale: 3, null: false
    t.decimal "south_limit", precision: 6, scale: 3, null: false
    t.boolean "wrapped", default: false
    t.index ["country_id"], name: "index_latlon_boundaries_on_country_id"
  end

  create_table "oauth_access_grants", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.string "scopes"
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "party_identifiers", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "party_type", null: false
    t.string "identifier", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "searchjoy_conversions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "search_id"
    t.string "convertable_type"
    t.bigint "convertable_id"
    t.datetime "created_at"
    t.index ["convertable_type", "convertable_id"], name: "index_searchjoy_conversions_on_convertable"
    t.index ["search_id"], name: "index_searchjoy_conversions_on_search_id"
  end

  create_table "searchjoy_searches", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.string "search_type"
    t.string "query"
    t.string "normalized_query"
    t.string "search_family"
    t.integer "results_count"
    t.datetime "created_at"
    t.datetime "converted_at"
    t.index ["created_at"], name: "index_searchjoy_searches_on_created_at"
    t.index ["search_type", "created_at"], name: "index_searchjoy_searches_on_search_type_and_created_at"
    t.index ["search_type", "normalized_query", "created_at"], name: "index_searchjoy_searches_on_search_type_query"
    t.index ["user_id"], name: "index_searchjoy_searches_on_user_id"
  end

  create_table "universities", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "party_identifier"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0
    t.string "unlock_token"
    t.datetime "locked_at", precision: nil
    t.string "first_name", null: false
    t.string "last_name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "admin", default: false, null: false
    t.string "address"
    t.string "address2"
    t.string "country"
    t.string "phone"
    t.boolean "contact_only", default: false
    t.integer "rights_transferred_to_id"
    t.string "rights_transfer_reason"
    t.string "party_identifier"
    t.boolean "collector", default: false, null: false
    t.string "unikey"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["rights_transferred_to_id"], name: "index_users_on_rights_transferred_to_id"
    t.index ["unikey"], name: "index_users_on_unikey", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "versions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", size: :long
    t.datetime "created_at", precision: nil
    t.text "object_changes", size: :long
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
end
