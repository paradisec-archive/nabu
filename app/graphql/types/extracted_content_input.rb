# frozen_string_literal: true

module Types
  class ExtractedContentInput < Types::BaseInputObject
    description 'Structured extracted content for an essence, typed by extractor semantics'

    argument :content_type, Types::ExtractedContentTypeEnum
    argument :segments, [Types::ExtractedSegmentInput], required: false, description: 'Required for PDF content'
    argument :text, String, required: false, description: 'Required for TEXT content'

    # The segment type each segments-shaped content type must be made of, so a new structured
    # format is one entry here plus its enum values.
    SEGMENT_TYPES = {
      'pdf' => 'page'
    }.freeze

    # GraphQL cannot express conditional requiredness (TEXT needs text, PDF needs PAGE
    # segments), so the combinations are enforced here at the schema boundary. Prepares into
    # the extracted_content / extracted_content_type storage pair: nabu owns the serialisation
    # of segments to JSON, so ingest clients never send pre-serialised blobs.
    def prepare
      if content_type == 'text'
        validate_flat!
        { extracted_content: text, extracted_content_type: content_type }
      else
        validate_segments!(SEGMENT_TYPES.fetch(content_type))
        { extracted_content: segments.map(&:to_storage).to_json, extracted_content_type: content_type }
      end
    end

    private

    def label
      content_type.upcase
    end

    def validate_flat!
      raise GraphQL::ExecutionError, 'extractedContent: TEXT content requires text' if text.blank?
      raise GraphQL::ExecutionError, 'extractedContent: TEXT content cannot have segments' if segments.present?
    end

    def validate_segments!(segment_type)
      raise GraphQL::ExecutionError, "extractedContent: #{label} content requires segments" if segments.blank?
      raise GraphQL::ExecutionError, "extractedContent: #{label} content cannot have text" if text.present?

      return if segments.all? { |segment| segment.type == segment_type }

      raise GraphQL::ExecutionError, "extractedContent: #{label} content requires #{segment_type.upcase} segments"
    end
  end
end
