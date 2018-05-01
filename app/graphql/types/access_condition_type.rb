Types::AccessConditionType = GraphQL::ObjectType.define do
  name 'AccessCondition'

  field :name, types.String
  field :items, types[Types::ItemType]
  field :collections, types[Types::CollectionType]
end
