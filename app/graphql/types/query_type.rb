Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'

  field :items, types[Types::ItemType] do
    argument :limit, types.Int, default_value: 10
    argument :order, types.String, default_value: :id
    resolve ->(object, args, ctx) {
      Item.limit(args['limit']).order(args['order'] || :id)
    }
  end
end
