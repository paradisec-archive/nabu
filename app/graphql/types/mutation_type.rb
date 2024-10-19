module Types
  class MutationType < Types::BaseObject
    field :essence_update, mutation: Mutations::EssenceUpdate
    field :essence_create, mutation: Mutations::EssenceCreate
    field :set_collection_has_deposit_form, mutation: Mutations::SetCollectionHasDepositForm
  end
end
