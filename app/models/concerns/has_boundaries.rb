module HasBoundaries
  extend ActiveSupport::Concern

  included do
    validate :extent_not_swapped

    def boundaries
      return unless has_all_boundaries?
      OpenStruct.new(
        north_limit: north_limit,
        south_limit: south_limit,
        west_limit: west_limit,
        east_limit: east_limit
      )
    end

    def has_all_boundaries?
      north_limit? && south_limit? && west_limit? && east_limit?
    end

    private

    # A genuine antimeridian crossing has a non-positive east edge, so east < west
    # with both edges positive can only be a swapped extent.
    def extent_not_swapped
      return unless west_limit && east_limit
      return unless east_limit < west_limit && east_limit > 0

      errors.add(:east_limit, 'is west of the west limit — the extent is swapped')
    end
  end
end
