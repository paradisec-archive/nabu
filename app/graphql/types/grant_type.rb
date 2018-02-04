Types::GrantType = GraphQL::ObjectType.define do
  name 'Grant'

  field :id, !types.ID
  field :identifier, types.String, property: :grant_identifier
  field :funding_body, Types::FundingBodyType
  field :colleciton, Types::CollectionType
end