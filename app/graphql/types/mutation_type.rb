module Types
  class MutationType < Types::BaseObject
    field :essence_update, mutation: Mutations::EssenceUpdate
    field :essence_create, mutation: Mutations::EssenceCreate
  end
end
