Types::LanguageType = GraphQL::ObjectType.define do
  name 'Language'

  field :id, !types.ID
  field :code, types.String
  field :name, types.String
  field :countries, Types::CountryType
end
