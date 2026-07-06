# frozen_string_literal: true

module Types
  class EssenceAttributes < Types::BaseInputObject
    description 'Attributes for creating or updating an essence'
    argument :bitrate, GraphQL::Types::BigInt, required: false
    argument :channels, Integer, required: false
    argument :duration, Float, required: false
    argument :extracted_content, Types::ExtractedContentInput, required: false
    argument :fps, Integer, required: false
    argument :mimetype, String
    argument :samplerate, Integer, required: false
    argument :size, GraphQL::Types::BigInt

    # ExtractedContentInput prepares itself into the extracted_content / extracted_content_type
    # storage pair; flatten it here so the model keeps a single write API for extracted content.
    def prepare
      attributes = to_h
      storage = attributes.delete(:extracted_content)
      return attributes if storage.nil?

      attributes.merge(storage)
    end
  end
end
