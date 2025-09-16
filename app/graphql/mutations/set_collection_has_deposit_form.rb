# frozen_string_literal: true

module Mutations
  class SetCollectionHasDepositForm < BaseMutation
    description 'Marks as collection a having a deposit form'

    argument :identifier, String, required: true

    def resolve(identifier:)
      collection = Collection.find_by!(identifier: collection_identifier)
      authorize! :update, collection

      collection.has_deposit_form = true

      raise GraphQL::ExecutionError.new 'Error updating collection', extensions: collection.errors.to_hash unless collection.save

      {}
    end
  end
end
