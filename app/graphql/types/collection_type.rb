Types::CollectionType = GraphQL::ObjectType.define do
  name 'Collection'
  # description 'The query root for this schema'
  # Add root-level fields here.
  # They will be entry points for queries on your schema.

  # field :items, Types::ItemType, field: Fields::FetchField.build(type: Types::ItemType, model: Item)
  # field :collections, Types::CollectionType, field: Fields::FetchField.build(type: Types::CollectionType, model: Collection)
  # field :node, GraphQL::Relay::Node.field
end
