class Types::ItemBwfCsvType < Types::BaseObject
  field :collection_identifier, String, null: false
  field :created_at, GraphQL::Types::ISO8601DateTime
  field :csv, String, null: false
  field :full_identifier, String, null: false
  field :item_identifier, String, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime
end
