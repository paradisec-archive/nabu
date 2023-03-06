class Types::FundingBodyType < Types::BaseObject

  field :id, ID, null: false
  field :name, String, null: false
  field :key_prefix, String, null: true, camelize: false
  field :grants, [Types::GrantType, null: true], null: true
  field :funded_collections, [Types::CollectionType, null: true], method: :collections, null: true, camelize: false
end
