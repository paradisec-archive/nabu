# frozen_string_literal: true

module Mutations
  class EssenceUpdate < BaseMutation
    description 'Updates a essence by id'

    field :essence, Types::EssenceType, null: false

    argument :attributes, Types::EssenceAttributes, required: true
    argument :id, ID, required: true

    def resolve(id:, attributes:)
      essence = ::Essence.find(id)
      authorize! :update, essence

      raise GraphQL::ExecutionError.new 'Error updating essence', extensions: essence.errors.to_hash unless essence.update(**attributes)

      { essence: }
    end
  end
end
