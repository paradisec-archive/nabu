# frozen_string_literal: true

module Types
  class SegmentTypeEnum < Types::BaseEnum
    graphql_name 'SegmentType'
    description 'The kind of location a segment of extracted content is addressed by'

    value 'PAGE', 'A PDF page', value: 'page'
  end
end
