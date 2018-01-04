Types::ItemType = GraphQL::ObjectType.define do
  name 'Item'

  field :id, !types.ID
  field :identifier, !types.String
  field :full_identifier, !types.String
  field :title, types.String
  field :description, types.String
  field :originated_on, types.String
  field :originated_on_narrative, types.String
  field :permalink, !types.String, property: :full_path
  field :collector, Types::PersonType
  field :countries, types[Types::CountryType]
  field :subject_languages, types[Types::LanguageType]
  field :content_languages, types[Types::LanguageType]
  field :agents, types[Types::PersonType]
  field :citation, types.String
  field :collection, Types::CollectionType
end
