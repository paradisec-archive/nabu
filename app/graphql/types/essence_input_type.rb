# frozen_string_literal: true

module Types
  class EssenceInputType < Types::BaseInputObject
    description 'Attributes for creating or updating an essence'
    argument :item_identifier, String
    argument :collection_identifier, String
    argument :filename, String
    # field :mimetype, String
    # field :bitrate, Integer
    # field :samplerate, Integer
    # field :size, Integer
    # field :duration, Float
    # field :channels, Integer
    # field :fps, Integer
    # field :doi, String
    # field :derived_files_generated, Boolean
    # field :doi_xml, String, method: :to_doi_xml, camelize: false
    # field :citation, String
    # field :permalink, String, method: :full_path
  end
end
