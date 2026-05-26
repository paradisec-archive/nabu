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

    def self.normalise(value)
      return nil if value.nil?

      FROM_PCDM[value] || value
    end

    def self.to_pcdm(internal_value)
      TO_PCDM[internal_value]
    end

    def self.from_pcdm(pcdm_uri)
      FROM_PCDM[pcdm_uri]
    end
  end
end
