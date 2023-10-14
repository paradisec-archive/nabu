# frozen_string_literal: true

module Types
  class EssenceInputType < Types::BaseInputObject
    description 'Attributes for creating or updating an essence'
    argument :item_identifier, String
    argument :collection_identifier, String
    argument :filename, String
    argument :mimetype, String
    argument :size, Integer
    argument :bitrate, Integer, required: false
    argument :samplerate, Integer, required: false
    argument :duration, Float, required: false
    argument :channels, Integer, required: false
    argument :fps, Integer, required: false
  end
end
