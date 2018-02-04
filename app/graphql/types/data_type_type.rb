Types::DataTypeType = GraphQL::ObjectType.define do
  name 'DataType'

  field :id, !types.ID
  field :name, !types.String
  field :items, types[Types::ItemType]
end