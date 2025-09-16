# frozen_string_literal: true

module Mutations
  class EssenceCreate < BaseMutation
    description 'Creates a new essence'

    field :essence, Types::EssenceType, null: false

    argument :item_identifier, String
    argument :collection_identifier, String
    argument :filename, String
    argument :attributes, Types::EssenceAttributes, required: true

    def resolve(item_identifier:, collection_identifier:, filename:, attributes:)
      collection = Collection.find_by!(identifier: collection_identifier)
      authorize! :read, collection

      item = collection.items.find_by(identifier: item_identifier)
      authorize! :read, item

      authorize! :create, Essence

      essence = ::Essence.new(filename:, item_id: item.id, **attributes)

      raise GraphQL::ExecutionError.new 'Error creating essence', extensions: essence.errors.to_hash unless essence.save

      { essence: }
    end
  end
end
