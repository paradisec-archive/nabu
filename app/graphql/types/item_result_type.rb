Types::ItemResultType = GraphQL::ObjectType.define do
  name 'ItemResult'

  field :total, !types.Int
  field :next_page, types.Int
  field :results, !types[Types::ItemType]
end
