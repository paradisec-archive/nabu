class Types::BoundaryType < Types::BaseObject

  field :north_limit, Float, null: false
  field :south_limit, Float, null: false
  field :west_limit, Float, null: false
  field :east_limit, Float, null: false
end