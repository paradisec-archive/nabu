module HasBoundaries
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
end