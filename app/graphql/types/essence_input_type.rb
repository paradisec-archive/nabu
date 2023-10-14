# frozen_string_literal: true

module Types
  class EssenceInputType < Types::BaseInputObject
    description 'Attributes for creating or updating an essence'
    argument :item_identifier, String
    argument :collection_identifier, String
    argument :filename, String
    argument :mimetype, String
    argument :bitrate, Integer
    argument :samplerate, Integer
    argument :size, Integer
    argument :duration, Float
    argument :channels, Integer
    argument :fps, Integer
  end
end
