# frozen_string_literal: true

module Types
  class EssenceAttributes < Types::BaseInputObject
    description 'Attributes for creating or updating an essence'
    argument :mimetype, String
    argument :size, GraphQL::Types::BigInt
    argument :bitrate, Integer, required: false
    argument :samplerate, Integer, required: false
    argument :duration, Float, required: false
    argument :channels, Integer, required: false
    argument :fps, Integer, required: false
  end
end
