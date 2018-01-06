Types::FundingBodyType = GraphQL::ObjectType.define do
  name 'FundingBody'

  field :id, !types.ID
  field :name, !types.String
  field :key_prefix, types.String
  field :grants, types[Types::GrantType]
  field :funded_collections, types[Types::CollectionType], property: :collections
end