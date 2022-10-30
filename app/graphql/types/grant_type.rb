class Types::GrantType < Types::BaseObject

  field :id, ID, null: false
  field :identifier, String, method: :grant_identifier, null: true
  field :funding_body, Types::FundingBodyType, null: true
  field :colleciton, Types::CollectionType, null: true
end