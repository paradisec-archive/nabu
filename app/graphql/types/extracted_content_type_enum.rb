# frozen_string_literal: true

module Types
  class ExtractedContentTypeEnum < Types::BaseEnum
    graphql_name 'ExtractedContentType'
    description 'Which extractor semantics produced the extracted content'

    value 'TEXT', 'Flat plain text', value: 'text'
    value 'PDF', 'One segment per PDF page', value: 'pdf'
    value 'ELAN', 'One segment per ELAN annotation', value: 'elan'
  end
end
