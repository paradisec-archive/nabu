Types::PersonType = GraphQL::ObjectType.define do
  name 'Person'

  field :id, !types.ID
  field :first_name, types.String
  field :last_name, types.String
  field :name, types.String
  field :country, types.String
  field :collected_items, Types::ItemType, property: :owned_items
end
