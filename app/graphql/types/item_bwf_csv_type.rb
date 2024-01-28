class Types::ItemBwfCsvType < Types::BaseObject
  field :full_identifier, String, null: false
  field :collection_identifier, String, null: false
  field :item_identifier, String, null: false
  field :csv, String, null: false
  field :created_at, GraphQL::Types::ISO8601DateTime
  field :updated_at, GraphQL::Types::ISO8601DateTime
end
