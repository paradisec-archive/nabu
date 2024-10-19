# frozen_string_literal: true

module Mutations
  class SetCollectionHasDepositForm < BaseMutation
    description 'Marks as collection a having a deposit form'

    argument :identifier, String, required: true

    def resolve(identifier:)
      raise(GraphQL::ExecutionError, 'Not authorised') unless context[:admin_authenticated]

      collection = ::Collection.find_by(identifier:)
      collection.has_deposit_form = true

      raise GraphQL::ExecutionError.new 'Error updating collection', extensions: collection.errors.to_hash unless collection.save

      {}
    end
  end
end
