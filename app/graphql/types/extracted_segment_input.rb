# frozen_string_literal: true

module Types
  class ExtractedSegmentInput < Types::BaseInputObject
    description 'One location-addressed segment of extracted content'

    argument :end_ms, Integer, required: false, description: 'TIME_ALIGNED_ANNOTATION segments only'
    argument :page, Integer, required: false, description: 'PAGE segments only'
    argument :start_ms, Integer, required: false, description: 'TIME_ALIGNED_ANNOTATION segments only'
    argument :text, String
    argument :tier, String, required: false, description: "TIME_ALIGNED_ANNOTATION segments only - the depositor's TIER_ID verbatim"
    argument :type, Types::SegmentTypeEnum

    # GraphQL cannot express per-variant requiredness, so each segment type's location fields
    # (Essence::SEGMENT_REQUIRED_FIELDS, the single source of truth) are enforced here at the
    # schema boundary.
    def prepare
      raise GraphQL::ExecutionError, 'extractedContent: segment text cannot be blank' if text.blank?

      missing = Essence::SEGMENT_REQUIRED_FIELDS.fetch(type).reject { |field| public_send(field).present? }
      raise GraphQL::ExecutionError, "extractedContent: #{type.upcase.tr('-', '_')} segments require #{missing.join(', ')}" if missing.any?

      self
    end

    # Storage keys match the nested index mapping (snake_case), so the stored JSON can be
    # indexed without translation.
    def to_storage
      to_h.compact
    end
  end
end
