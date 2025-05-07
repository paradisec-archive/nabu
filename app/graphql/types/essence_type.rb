# frozen_string_literal: true

module Types
  class EssenceType < Types::BaseObject
    field :id, ID, null: false
    field :item_id, Integer
    field :item, Types::ItemType
    field :collection_id, Integer
    field :collection, Types::CollectionType
    field :filename, String
    field :mimetype, String
    field :bitrate, GraphQL::Types::BigInt
    field :samplerate, Integer
    field :size, GraphQL::Types::BigInt
    field :duration, Float
    field :channels, Integer
    field :fps, Integer
    field :created_at, GraphQL::Types::ISO8601DateTime
    field :updated_at, GraphQL::Types::ISO8601DateTime
    field :doi, String
    field :derived_files_generated, Boolean
    field :doi_xml, String, method: :to_doi_xml, camelize: false
    field :citation, String
    field :permalink, String, method: :full_path
  end
end
