# frozen_string_literal: true

module Mutations
  class EssenceCreate < BaseMutation
    description 'Creates a new essence'

    field :essence, Types::EssenceType, null: false

    argument :essence_input, Types::EssenceInputType, required: true

    def resolve(essence_input:)
      input = essence_input.to_h
      collection_identifier = input.delete(:collection_identifier)
      collection = Collection.find_by(identifier: collection_identifier)

      item_identifier = input.delete(:item_identifier)
      item = collection.items.find_by(identifier: item_identifier)
      input[:item_id] = item.id
      Rails.logger.info "input: #{input}"

      essence = ::Essence.new(**input)
      raise GraphQL::ExecutionError.new 'Error creating essence', extensions: essence.errors.to_hash unless essence.save

      { essence: }
    end
  end
end
