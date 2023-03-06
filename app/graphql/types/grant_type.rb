class Types::GrantType < Types::BaseObject

  field :id, ID, null: false
  field :identifier, String, method: :grant_identifier, null: true
  field :funding_body, Types::FundingBodyType, null: true, camelize: false
  field :collection, Types::CollectionType, null: true
end
