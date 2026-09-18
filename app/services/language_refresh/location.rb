module LanguageRefresh
  # A Source publishes a point; Nabu keeps a Bounding box. An empty box becomes that point on all
  # four sides, a box that already exists is never changed whoever set it, and a point far outside
  # one is a Location warning for a person rather than an edit. The point itself is never stored, so
  # a warning is measured afresh every Run and repeats until someone resolves it.
  module Location
    WARNING_THRESHOLD_KM = 250
    EARTH_RADIUS_KM = 6371.0

    LIMITS = %i[north_limit south_limit west_limit east_limit].freeze

    Point = Data.define(:latitude, :longitude)

    class << self
      def point(latitude, longitude)
        latitude = latitude.presence
        longitude = longitude.presence
        return if latitude.nil? || longitude.nil?

        Point.new(latitude: Float(latitude), longitude: Float(longitude))
      rescue ArgumentError, TypeError
        Rails.logger.warn("Language Refresh read no point from latitude #{latitude.inspect}, longitude #{longitude.inspect}")
        nil
      end

      # A Source publishes a point, never an extent, so a box from one is that point on four sides.
      def limits(point)
        return {} if point.nil?

        { north_limit: point.latitude, south_limit: point.latitude, west_limit: point.longitude, east_limit: point.longitude }
      end

      # A limit of zero is a real edge, so emptiness here is only ever nil.
      def boxless?(language)
        limits_of(language).all?(&:nil?)
      end

      # Kilometres past the nearest edge, or nil where there is nothing to disagree: no point, or no
      # box to measure against. A box only partly filled in is nobody's to complete.
      def warning_distance(language, point)
        return if point.nil? || !language.has_all_boundaries?

        distance = distance_from_box(language, point)
        distance.round if distance > WARNING_THRESHOLD_KM
      end

      private

      def limits_of(language)
        language.slice(*LIMITS).values
      end

      def distance_from_box(language, point)
        nearest = Point.new(
          latitude: point.latitude.clamp(*[language.south_limit, language.north_limit].minmax),
          longitude: nearest_longitude(point.longitude, language.west_limit, language.east_limit)
        )

        haversine(point, nearest)
      end

      # A box may cross the antimeridian, where its east edge is the lower number, so longitudes are
      # compared as angles rather than as numbers.
      def nearest_longitude(longitude, west, east)
        return longitude if within_longitudes?(longitude, west, east)

        [west, east].min_by { |edge| degrees_apart(longitude, edge) }
      end

      def within_longitudes?(longitude, west, east)
        return longitude.between?(west, east) if west <= east

        longitude >= west || longitude <= east
      end

      # The short way round, so 179°E and 179°W are two degrees apart.
      def degrees_apart(one, other)
        (((one - other + 180) % 360) - 180).abs
      end

      def haversine(from, to)
        from_latitude = to_radians(from.latitude)
        to_latitude = to_radians(to.latitude)
        latitude_delta = to_latitude - from_latitude
        longitude_delta = to_radians(degrees_apart(to.longitude, from.longitude))

        chord = (Math.sin(latitude_delta / 2)**2) +
                (Math.cos(from_latitude) * Math.cos(to_latitude) * (Math.sin(longitude_delta / 2)**2))
        2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(chord))
      end

      def to_radians(degrees)
        degrees * Math::PI / 180
      end
    end
  end
end
