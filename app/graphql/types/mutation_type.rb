module Types
  class MutationType < Types::BaseObject
    field :essence_create, mutation: Mutations::EssenceCreate
  end
end
