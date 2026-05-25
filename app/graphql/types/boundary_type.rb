class Types::BoundaryType < Types::BaseObject
  field :east_limit, Float, null: false, camelize: false
  field :north_limit, Float, null: false, camelize: false
  field :south_limit, Float, null: false, camelize: false
  field :west_limit, Float, null: false, camelize: false
end
