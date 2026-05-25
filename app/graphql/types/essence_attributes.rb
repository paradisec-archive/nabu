# frozen_string_literal: true

module Types
  class EssenceAttributes < Types::BaseInputObject
    description 'Attributes for creating or updating an essence'
    argument :bitrate, GraphQL::Types::BigInt, required: false
    argument :channels, Integer, required: false
    argument :duration, Float, required: false
    argument :extracted_text, String, required: false
    argument :fps, Integer, required: false
    argument :mimetype, String
    argument :samplerate, Integer, required: false
    argument :size, GraphQL::Types::BigInt
  end
end
