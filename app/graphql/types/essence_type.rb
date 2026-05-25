# frozen_string_literal: true

module Types
  class EssenceType < Types::BaseObject
    field :bitrate, GraphQL::Types::BigInt
    field :channels, Integer
    field :citation, String
    field :collection, Types::CollectionType
    field :collection_id, Integer
    field :created_at, GraphQL::Types::ISO8601DateTime
    field :derived_files_generated, Boolean
    field :doi, String
    field :doi_xml, String, method: :to_doi_xml, camelize: false
    field :duration, Float
    field :filename, String
    field :fps, Integer
    field :id, ID, null: false
    field :item, Types::ItemType
    field :item_id, Integer
    field :mimetype, String
    field :permalink, String, method: :full_path
    field :samplerate, Integer
    field :size, GraphQL::Types::BigInt
    field :updated_at, GraphQL::Types::ISO8601DateTime
  end
end
