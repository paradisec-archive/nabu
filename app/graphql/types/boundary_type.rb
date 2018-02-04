Types::BoundaryType = GraphQL::ObjectType.define do
  name 'Boundary'

  field :north_limit, !types.Float
  field :south_limit, !types.Float
  field :west_limit, !types.Float
  field :east_limit, !types.Float
end