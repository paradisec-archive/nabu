module Oni
  module EntityType
    INTERNAL_TYPES = %w[Collection Item Essence].freeze

    TO_PCDM = {
      'Collection' => 'http://pcdm.org/models#Collection',
      'Item' => 'http://pcdm.org/models#Object',
      'Essence' => 'http://schema.org/MediaObject'
    }.freeze

    FROM_PCDM = TO_PCDM.invert.freeze

    PCDM_TYPES = TO_PCDM.values.freeze

    # The names the API speaks for the internal models, used for the entity_type facet buckets.
    # Only types listed here are renamed; anything else keeps its internal name. The spec requires
    # every facet value to be usable as a filter, so normalise accepts these back.
    TO_PUBLIC = {
      'Essence' => 'File'
    }.freeze

    FROM_PUBLIC = TO_PUBLIC.invert.freeze

    PUBLIC_TYPES = INTERNAL_TYPES.map { |type| TO_PUBLIC.fetch(type, type) }.freeze

    def self.normalise(value)
      return nil if value.nil?

      FROM_PCDM[value] || FROM_PUBLIC[value] || value
    end

    def self.to_pcdm(internal_value)
      TO_PCDM[internal_value]
    end

    def self.from_pcdm(pcdm_uri)
      FROM_PCDM[pcdm_uri]
    end

    def self.to_public(internal_value)
      TO_PUBLIC.fetch(internal_value, internal_value)
    end
  end
end
