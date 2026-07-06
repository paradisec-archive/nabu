# frozen_string_literal: true

module Types
  class ExtractedContentInput < Types::BaseInputObject
    description 'Structured extracted content for an essence, typed by extractor semantics'

    argument :content_type, Types::ExtractedContentTypeEnum
    argument :text, String, required: false, description: 'Required for TEXT content'
    argument :segments, [Types::ExtractedSegmentInput], required: false, description: 'Required for PDF content'

    # GraphQL cannot express conditional requiredness (TEXT needs text, PDF needs PAGE
    # segments), so the combinations are enforced here at the schema boundary.
    def prepare
      case content_type
      when 'text'
        validate_flat!
      when 'pdf'
        validate_segments!('PDF', 'page')
      end

      self
    end

    private

    def validate_flat!
      raise GraphQL::ExecutionError, 'extractedContent: TEXT content requires text' if text.blank?
      raise GraphQL::ExecutionError, 'extractedContent: TEXT content cannot have segments' if segments.present?
    end

    def validate_segments!(label, segment_type)
      raise GraphQL::ExecutionError, "extractedContent: #{label} content requires segments" if segments.blank?
      raise GraphQL::ExecutionError, "extractedContent: #{label} content cannot have text" if text.present?

      return if segments.all? { |segment| segment.type == segment_type }

      raise GraphQL::ExecutionError, "extractedContent: #{label} content requires #{segment_type.upcase} segments"
    end
  end
end
