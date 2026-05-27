# frozen_string_literal: true

module Mutations
  class EssenceCreate < BaseMutation
    description 'Creates a new essence'

    field :essence, Types::EssenceType, null: false

    argument :attributes, Types::EssenceAttributes, required: true
    argument :collection_identifier, String
    argument :filename, String
    argument :item_identifier, String
    argument :uploader_unikey, String, required: false,
             description: 'When called by an admin OAuth client (e.g. paragest), records the real uploader by their unikey.'

    def resolve(item_identifier:, collection_identifier:, filename:, attributes:, uploader_unikey: nil)
      collection = Collection.find_by!(identifier: collection_identifier)
      authorize! :read, collection

      item = collection.items.find_by(identifier: item_identifier)
      authorize! :read, item

      authorize! :create, Essence

      essence = ::Essence.new(filename:, item_id: item.id, created_by: resolve_uploader(uploader_unikey), **attributes)

      raise GraphQL::ExecutionError.new 'Error creating essence', extensions: essence.errors.to_hash unless essence.save

      { essence: }
    end

    private

    def resolve_uploader(unikey)
      user = context[:current_user]
      return user if user.is_a?(::User)
      return nil unless user.respond_to?(:admin?) && user.admin?
      return nil if unikey.blank?

      ::User.find_by(unikey:) || raise(GraphQL::ExecutionError, "No user with unikey '#{unikey}'")
    end
  end
end
