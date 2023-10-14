# frozen_string_literal: true

module Mutations
  class EssenceCreate < BaseMutation
    description 'Creates a new essence'

    field :essence, Types::EssenceType, null: false

    argument :item_identifier, String
    argument :collection_identifier, String
    argument :filename, String
    argument :attributes, Types::EssenceAttributes, required: true

    def resolve(item_identifier:, collection_identifier:, filename:, essence_input:)
      input = essence_input.to_h
      collection = Collection.find_by(identifier: collection_identifier)

      item = collection.items.find_by(identifier: item_identifier)
      input[:item_id] = item.id
      Rails.logger.info "input: #{input}"

      essence = ::Essence.new(filename:, **input)
      raise GraphQL::ExecutionError.new 'Error creating essence', extensions: essence.errors.to_hash unless essence.save

      { essence: }
    end
  end
end
