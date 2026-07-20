# frozen_string_literal: true

module Types
  class SegmentTypeEnum < Types::BaseEnum
    graphql_name 'SegmentType'
    description 'The kind of location a segment of extracted content is addressed by'

    value 'PAGE', 'A PDF page', value: 'page'
    value 'TIME_ALIGNED_ANNOTATION', 'A time-aligned annotation, such as an ELAN annotation', value: 'time-aligned-annotation'
  end
end
