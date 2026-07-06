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

    # The legacy flat extractedText argument is translated to the canonical storage pair at this
    # boundary so the model keeps a single write API for extracted content.
    def prepare
      attributes = to_h
      return attributes unless attributes.key?(:extracted_text)

      text = attributes.delete(:extracted_text)
      attributes.merge(extracted_content: text, extracted_content_type: text.nil? ? nil : 'text')
    end
  end
end
