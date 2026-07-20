module Oni
  # Single source of truth for what GET /capabilities declares. The search validator derives
  # its accepted filter keys and type rules from FILTERS, and the controller's aggs must stay
  # within FACETS (the spec requires every facet to also be a filter).
  module SearchCapabilities
    API_VERSION = '0.1.0'.freeze

    FILTERS = {
      'languages_with_code' => { type: 'string', label: 'Language' },
      'countries' => { type: 'string', label: 'Country' },
      'collector_name' => { type: 'string', label: 'Collector' },
      'collection_title' => { type: 'string', label: 'Collection' },
      'access_condition_name' => { type: 'string', label: 'Access conditions' },
      'encodingFormat' => { type: 'string', label: 'Media type' },
      'rootCollection' => { type: 'string', label: 'Root collection' },
      'originatedOn' => { type: 'date', label: 'Date originated' },
      'entity_type' => { type: 'string', label: 'Entity type' },
      'full_identifier' => { type: 'string', label: 'Identifier' }
    }.freeze

    FACETS = FILTERS.transform_values { |declaration| declaration.slice(:label) }.freeze

    def self.filter_type(key)
      FILTERS.dig(key, :type)
    end
  end
end
