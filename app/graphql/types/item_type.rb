class Types::ItemType < Types::BaseObject
  field :access_class, String, null: true, camelize: false
  field :access_condition, Types::AccessConditionType, null: true, camelize: false
  field :access_condition_name, String, null: true, camelize: false
  field :access_narrative, String, null: true, camelize: false
  field :born_digital, Boolean, null: true, camelize: false
  field :boundaries, Types::BoundaryType, null: true
  field :citation, String, null: true
  field :collection, Types::CollectionType, null: false
  field :collector, Types::PersonType, null: false
  field :content_languages, [Types::LanguageType, null: true], null: true, camelize: false
  field :countries, [Types::CountryType, null: true], null: true
  field :created_at, GraphQL::Types::ISO8601DateTime, camelize: false
  field :data_categories, [Types::DataCategoryType, null: true], null: true, camelize: false
  field :data_types, [Types::DataTypeType, null: true], null: true, camelize: false
  field :description, String, null: true
  field :dialect, String, null: true
  field :digitised_on, String, null: true, camelize: false
  field :discourse_type, Types::DiscourseTypeType, null: true, camelize: false
  field :doi, String, null: true
  field :doi_json, String, method: :to_doi_json, null: true, camelize: false
  field :essences, [Types::EssenceType, null: true], null: true
  field :essences_count, Integer, null: true, camelize: false
  field :full_identifier, String, null: false, camelize: false
  field :id, ID, null: false
  field :identifier, String, null: false
  field :ingest_notes, String, null: true, camelize: false
  field :item_agents, [Types::AgentType, null: true], null: true, camelize: false
  field :language, String, null: true
  field :metadata_exportable, Boolean, null: false, camelize: false
  field :operator, Types::PersonType, null: true
  field :original_media, String, null: true, camelize: false
  field :originated_on, String, null: true, camelize: false
  field :originated_on_narrative, String, null: true, camelize: false
  field :permalink, String, method: :full_path, null: false
  field :private, Boolean, null: true
  field :public, Boolean, method: :public?, null: true
  field :received_on, String, null: true, camelize: false
  field :region, String, null: true
  field :subject_languages, [Types::LanguageType, null: true], null: true, camelize: false
  field :title, String, null: true
  field :tracking, String, null: true
  field :university, Types::UniversityType, null: true
  field :updated_at, GraphQL::Types::ISO8601DateTime, camelize: false
end
