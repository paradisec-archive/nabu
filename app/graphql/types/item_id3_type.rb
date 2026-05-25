class Types::ItemId3Type < Types::BaseObject
  field :collection_identifier, String, null: false
  field :created_at, GraphQL::Types::ISO8601DateTime
  field :full_identifier, String, null: false
  field :item_identifier, String, null: false
  field :txt, String, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime
end
