Types::CountryType = GraphQL::ObjectType.define do
  name 'Country'

  field :id, !types.ID
  field :code, !types.String
  field :name, !types.String
  field :languages, types[Types::LanguageType]
  field :boundaries, types[Types::BoundaryType], property: :latlon_boundary
end
