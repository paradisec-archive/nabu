class Types::GrantType < Types::BaseObject
  field :collection, Types::CollectionType, null: true
  field :funding_body, Types::FundingBodyType, null: true, camelize: false
  field :id, ID, null: false
  field :identifier, String, method: :grant_identifier, null: true
end
