Types::DiscourseTypeType = GraphQL::ObjectType.define do
  name 'DiscourseType'

  field :id, !types.ID
  field :name, !types.String
  field :itesm, types[Types::ItemType]
end