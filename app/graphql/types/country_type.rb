Types::CountryType = GraphQL::ObjectType.define do
  name 'Country'

  field :id, !types.ID
  field :code, types.String
  field :name, types.String
  field :retired, types.Boolean
  field :arhive_link, types.String, property: :language_archive_link
  field :languages, Types::LanguageType
end
