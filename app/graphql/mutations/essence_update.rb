# frozen_string_literal: true

module Mutations
  class EssenceUpdate < BaseMutation
    description "Updates a essence by id"

    field :essence, Types::EssenceType, null: false

    argument :id, ID, required: true
    argument :essence_input, Types::EssenceInputType, required: true

    def resolve(id:, essence_input:)
      essence = ::Essence.find(id)
      raise GraphQL::ExecutionError.new "Error updating essence", extensions: essence.errors.to_hash unless essence.update(**essence_input)

      { essence: essence }
    end
  end
end
