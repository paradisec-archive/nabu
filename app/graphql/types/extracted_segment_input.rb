# frozen_string_literal: true

module Types
  class ExtractedSegmentInput < Types::BaseInputObject
    description 'One location-addressed segment of extracted content'

    argument :type, Types::SegmentTypeEnum
    argument :text, String
    argument :page, Integer, required: false, description: 'PAGE segments only'

    # GraphQL cannot express per-variant requiredness, so each segment type's location
    # fields are enforced here at the schema boundary.
    def prepare
      raise GraphQL::ExecutionError, 'extractedContent: segment text cannot be blank' if text.blank?

      case type
      when 'page'
        raise GraphQL::ExecutionError, 'extractedContent: PAGE segments require page' if page.nil?
      end

      self
    end
  end
end
