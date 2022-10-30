class Types::ItemType < Types::BaseObject

  field :id, ID, null: false
  field :identifier, String, null: false
  field :full_identifier, String, null: false
  field :collection, Types::CollectionType, null: false
  field :essences, [Types::EssenceType, null: true], null: true
  field :essences_count, Integer, null: true
  field :title, String, null: true
  field :description, String, null: true
  field :originated_on, String, null: true
  field :originated_on_narrative, String, null: true
  field :collector, Types::PersonType, null: false
  field :operator, Types::PersonType, null: true
  field :university, Types::UniversityType, null: true
  field :discourse_type, Types::DiscourseTypeType, null: true
  field :countries, [Types::CountryType, null: true], null: true
  field :subject_languages, [Types::LanguageType, null: true], null: true
  field :content_languages, [Types::LanguageType, null: true], null: true
  field :item_agents, [Types::AgentType, null: true], null: true
  field :data_categories, [Types::DataCategoryType, null: true], null: true
  field :data_types, [Types::DataTypeType, null: true], null: true
  field :boundaries, Types::BoundaryType, null: true
  field :language, String, null: true
  field :dialect, String, null: true
  field :access_class, String, null: true
  field :access_narrative, String, null: true
  field :access_condition_name, String, null: true
  field :access_condition, Types::AccessConditionType, null: true
  field :region, String, null: true
  field :original_media, String, null: true
  field :born_digital, Boolean, null: true
  field :received_on, String, null: true
  field :digitised_on, String, null: true
  field :ingest_notes, String, null: true
  field :tracking, String, null: true
  field :originated_on_narrative, String, null: true
  field :doi, String, null: true
  field :doi_xml, String, method: :to_doi_xml, null: true
  field :public, Boolean, method: :public?, null: true
  field :private, Boolean, null: true
  field :citation, String, null: true
  field :permalink, String, method: :full_path, null: false
end
