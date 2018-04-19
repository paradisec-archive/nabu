Types::ItemType = GraphQL::ObjectType.define do
  name 'Item'

  field :id, !types.ID
  field :identifier, !types.String
  field :full_identifier, !types.String
  field :collection, !Types::CollectionType
  field :essences, types[Types::EssenceType]
  field :essences_count, types.Int
  field :title, types.String
  field :description, types.String
  field :originated_on, types.String
  field :originated_on_narrative, types.String
  field :collector, !Types::PersonType
  field :operator, Types::PersonType
  field :university, Types::UniversityType
  field :discourse_type, Types::DiscourseTypeType
  field :countries, types[Types::CountryType]
  field :subject_languages, types[Types::LanguageType]
  field :content_languages, types[Types::LanguageType]
  field :agents, types[Types::PersonType]
  field :data_categories, types[Types::DataCategoryType]
  field :data_types, types[Types::DataTypeType]
  field :boundaries, Types::BoundaryType
  field :language, types.String
  field :dialect, types.String
  field :access_class, types.String
  field :access_narrative, types.String
  field :region, types.String
  field :original_media, types.String
  field :born_digital, types.Boolean
  field :received_on, types.String
  field :digitised_on, types.String
  field :ingest_notes, types.String
  field :tracking, types.String
  field :originated_on_narrative, types.String
  field :doi, types.String
  field :doi_xml, types.String, property: :to_doi_xml
  field :citation, types.String
  field :permalink, !types.String, property: :full_path
end
