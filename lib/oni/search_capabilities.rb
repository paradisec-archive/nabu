module Oni
  # Single source of truth for what GET /capabilities declares. The search validator derives
  # its accepted filter keys and type rules from FILTERS, and the controller's aggs must stay
  # within FACETS (the spec requires every facet to also be a filter).
  module SearchCapabilities
    API_VERSION = '0.3.0'.freeze

    # Nabu is read-only: no deposit or RO-Crate write surface. Spec 0.3.0 requires the block of
    # every implementation so clients never infer read-only-ness from a missing key, and requires
    # the remaining deposit fields to be omitted when supported is false.
    DEPOSIT = { supported: false }.freeze

    # Deleted URIs are indistinguishable from those that never existed - the Oni controller
    # rescues ActiveRecord::RecordNotFound into a 404 and nothing returns 410. The spec allows
    # one policy per implementation and forbids mixing them.
    TOMBSTONE_POLICY = '404'.freeze

    # Only these filter types accept range syntax; a range on any other type is a 400.
    RANGE_TYPES = %w[date number].freeze

    # index_field names the field in the search indices where it differs from the public filter
    # key. It is internal: /capabilities publishes type and label only.
    FILTERS = {
      'languages_with_code' => { type: 'string', label: 'Language' },
      'countries' => { type: 'string', label: 'Country' },
      'collector_name' => { type: 'string', label: 'Collector' },
      'collection_title' => { type: 'string', label: 'Collection' },
      'access_condition_name' => { type: 'string', label: 'Access conditions' },
      'encodingFormat' => { type: 'string', label: 'Media type' },
      'rootCollection' => { type: 'string', label: 'Root collection' },
      'originatedOn' => { type: 'date', label: 'Date originated', index_field: :originated_on },
      'entity_type' => { type: 'string', label: 'Entity type' },
      'full_identifier' => { type: 'string', label: 'Identifier' }
    }.freeze

    DECLARED_FILTERS = FILTERS.transform_values { |declaration| declaration.slice(:type, :label) }.freeze

    FACETS = FILTERS.transform_values { |declaration| declaration.slice(:label) }.freeze

    # The filters accepting range syntax, mapped to the field to query in the indices.
    RANGE_FILTERS = FILTERS
      .select { |_key, declaration| RANGE_TYPES.include?(declaration[:type]) }
      .transform_values { |declaration| declaration.fetch(:index_field) }
      .freeze

    def self.filter_type(key)
      FILTERS.dig(key, :type)
    end
  end
end
