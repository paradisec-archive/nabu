Types::UniversityType = GraphQL::ObjectType.define do
  name 'University'

  field :id, !types.ID
  field :name, !types.String
  field :party_identifier, types.String

  field :items, types[Types::ItemType]
  field :collections, types[Types::CollectionType]
end