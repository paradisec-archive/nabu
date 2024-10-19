# frozen_string_literal: true

module Mutations
  class EssenceUpdate < BaseMutation
    description 'Updates a essence by id'

    field :essence, Types::EssenceType, null: false

    argument :id, ID, required: true
    argument :attributes, Types::EssenceAttributes, required: true

    def resolve(id:, attributes:)
      raise(GraphQL::ExecutionError, 'Not authorised') unless context[:admin_authenticated]

      essence = ::Essence.find(id)
      raise GraphQL::ExecutionError.new 'Error updating essence', extensions: essence.errors.to_hash unless essence.update(**attributes)

      { essence: }
    end
  end
end
