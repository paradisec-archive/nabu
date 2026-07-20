module Oni
  class SearchValidator
    include ActiveModel::Validations

    # NOTE: We remap name to title below to match the database column
    SORT_FIELDS = %w[id name title relevance originated_on created_at updated_at].freeze
    ORDER_FIELDS = %w[asc desc].freeze

    ATTRIBUTES = %i[search_type query filters bounding_box geohash_precision limit offset order sort].freeze
    attr_accessor(*ATTRIBUTES)

    validate :validate_filters
    validate :validate_bounding_box
    validate :validate_entity_type_filter
    validates :geohash_precision, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }, allow_nil: true

    validates :order, inclusion: { in: ORDER_FIELDS, message: '%{value} is not a valid order' }, allow_nil: true
    validates :sort, inclusion: { in: SORT_FIELDS, message: '%{value} is not a valid sort field' }, allow_nil: true
    validates :limit, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 1000 }, allow_nil: true
    validates :offset, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
    validates :search_type, inclusion: { in: %w[basic advanced], message: '%{value} is not a valid searchType' }, allow_nil: true

    def initialize(params)
      permitted = ATTRIBUTES.map { | attr| attr.to_s.camelize(:lower).to_sym }
      bounding_box = { topRight: {}, bottomLeft: {} }
      object_params = params.permit(permitted, boundingBox: bounding_box)

      # Filter keys are validated against the /capabilities declaration rather than permitted:
      # the spec requires undeclared keys to be rejected with a 400, not silently dropped.
      # The plain-Hash conversion matters: HashWithIndifferentAccess would coerce the symbol
      # operator keys (:gte, :_or) the controller builds back into strings Searchkick ignores.
      raw_filters = params[:filters]
      @filters = raw_filters.respond_to?(:to_unsafe_h) ? raw_filters.to_unsafe_h.to_h : raw_filters

      object_params.each do |key, value|
        snake_key = key.to_s.underscore

        if %w[limit offset].include?(snake_key)
          value = value.to_i if value.present?
        end

        value = value.underscore if snake_key == 'sort' && value.present?

        snake_key = 'title' if snake_key == 'name'

        value = value.split(',') if snake_key == 'conforms_to' && value.present?

        send("#{snake_key}=", value) if respond_to?("#{snake_key}=")
      end

      @search_type ||= 'basic'
      @query ||= '*'
      @query = '*' if @query.empty?
      @filters ||= {}
      @limit ||= 1000
      @offset ||= 0
      @order ||= 'asc'
      @sort ||= 'relevance'
    end


    private

    def validate_filters
      return if filters.nil?

      unless filters.is_a?(Hash)
        errors.add(:filters, 'must be an object')
        return
      end

      filters.each do |key, value|
        declaration = Oni::SearchCapabilities::FILTERS[key]
        unless declaration
          errors.add(:filters, "'#{key}' is not a filter declared in /capabilities")
          next
        end

        case value
        when Array
          validate_filter_values(key, value)
        when Hash
          validate_filter_range(key, value, declaration)
        else
          errors.add(:filters, "value for '#{key}' must be an array or a range object")
        end
      end
    end

    def validate_filter_values(key, values)
      values.each do |item|
        unless item.is_a?(String)
          errors.add(:filters, "all values in '#{key}' must be strings")
        end
      end

      validate_originated_on_strings(values) if key == 'originatedOn'
    end

    # Legacy Oni date facet syntax, accepted alongside the spec's range object: each value is a
    # 'timestamp TO timestamp' string and the ranges are ORed.
    def validate_originated_on_strings(values)
      values.each do |range_string|
        next unless range_string.is_a?(String)

        unless range_string.match?(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z TO \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/)
          errors.add(:filters, "originatedOn range '#{range_string}' must be in format 'YYYY-MM-DDTHH:MM:SS.sssZ TO YYYY-MM-DDTHH:MM:SS.sssZ'")
        end
      end
    end

    def validate_filter_range(key, range, declaration)
      unless %w[date number].include?(declaration[:type])
        errors.add(:filters, "'#{key}' is a #{declaration[:type]} filter and does not accept a range object")
        return
      end

      bounds = range.slice('gte', 'lte')
      if bounds.empty? || bounds.size != range.size
        errors.add(:filters, "range for '#{key}' must contain at least one of gte and lte, and nothing else")
        return
      end

      bounds.each_value do |bound|
        valid = declaration[:type] == 'date' ? bound.is_a?(String) && parseable_date?(bound) : bound.is_a?(Numeric)
        errors.add(:filters, "range bounds for '#{key}' must be #{declaration[:type] == 'date' ? 'ISO 8601 date strings' : 'numbers'}") unless valid
      end
    end

    def parseable_date?(value)
      Date.iso8601(value)
      true
    rescue ArgumentError, TypeError
      false
    end

    def validate_bounding_box
      return if bounding_box.nil?

      unless bounding_box.key?('topRight') && bounding_box.key?('bottomLeft')
        errors.add(:boundingBox, 'must have topRight and bottomLeft keys')
        return
      end

      %w[topRight bottomLeft].each do |corner|
        point = bounding_box[corner]
        unless point.key?('lat') && point.key?('lng')
          errors.add(:boundingBox, "#{corner} must have lat and lng keys")
          next
        end

        lat = point['lat']
        lng = point['lng']
        unless lat.is_a?(Numeric) && lat.between?(-90, 90)
          errors.add(:boundingBox, "#{corner}.lat must be a number between -90 and 90")
        end
        unless lng.is_a?(Numeric) && lng.between?(-180, 180)
          errors.add(:boundingBox, "#{corner}.lng must be a number between -180 and 180")
        end
      end

      return if errors.any?

      if bounding_box['topRight']['lat'] == bounding_box['bottomLeft']['lat'] ||
         bounding_box['topRight']['lng'] == bounding_box['bottomLeft']['lng']
        errors.add(:boundingBox, 'topRight and bottomLeft must not have identical lat or lng values')
      end
    end

    def validate_entity_type_filter
      return unless filters.is_a?(Hash) && filters.key?('entity_type')

      entity_types = filters['entity_type']
      return unless entity_types.is_a?(Array)

      allowed = Oni::EntityType::INTERNAL_TYPES + Oni::EntityType::PCDM_TYPES
      entity_types.each do |value|
        next unless value.is_a?(String)

        unless allowed.include?(value)
          errors.add(:filters, "'#{value}' is not a valid entity_type")
        end
      end
    end
  end
end
