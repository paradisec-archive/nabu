Types::DataCategoryType = GraphQL::ObjectType.define do
  name 'DataCategory'
  field :id, !types.ID
  field :name, !types.String
  field :items, types[Types::ItemType]
end