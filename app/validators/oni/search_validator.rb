module Oni
  class SearchValidator
    include ActiveModel::Validations

    # NOTE: We remap name to title below to match the database column
    SORT_FIELDS = %w[id name title relevance originated_on].freeze
    ORDER_FIELDS = %w[asc desc].freeze

    ATTRIBUTES = %i[search_type query filters bounding_box geohash_precision limit offset order sort].freeze
    attr_accessor(*ATTRIBUTES)

    validate :validate_filters
    validate :validate_bounding_box
    validate :validate_originated_on
    validates :geohash_precision, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }, allow_nil: true

    validates :order, inclusion: { in: ORDER_FIELDS, message: '%{value} is not a valid order' }, allow_nil: true
    validates :sort, inclusion: { in: SORT_FIELDS, message: '%{value} is not a valid sort field' }, allow_nil: true
    validates :limit, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 1000 }, allow_nil: true
    validates :offset, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
    validates :search_type, inclusion: { in: %w[basic advanced], message: '%{value} is not a valid searchType' }, allow_nil: true

    def initialize(params)
      permitted = ATTRIBUTES.map { | attr| attr.to_s.camelize(:lower).to_sym }
      filters = { languages_with_code: [], countries: [], collector_name: [], collection_title: [], access_condition_name: [], encodingFormat: [], rootCollection: [], originatedOn: [], entity_type: [] }
      bounding_box = { topRight: {}, bottomLeft: {} }
      object_params = params.permit(permitted, filters:, boundingBox: bounding_box)

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

    def transform_originated_on_filter
      originated_on = @filters['originatedOn']
      return unless originated_on.is_a?(Array)

      ranges = parse_originated_on_ranges(originated_on)
      @filters['originatedOn'] = { 'ranges' => ranges }
    end

    def parse_originated_on_ranges(originated_on_array)
      originated_on_array.map do |range_string|
        # Parse format: 'YYYY-MM-DDTHH:MM:SS.sssZ TO YYYY-MM-DDTHH:MM:SS.sssZ'
        parts = range_string.split(' TO ')
        next nil if parts.length != 2

        { 'from' => parts[0].strip, 'to' => parts[1].strip }
      end.compact
    end

    def validate_filters
      return if filters.nil?

      filters.each do |key, value|
        unless key.is_a?(String)
          errors.add(:filters, "key '#{key}' must be a string")
        end

        unless value.is_a?(Array)
          errors.add(:filters, "value for '#{key}' must be an array")
          next
        end

        value.each do |item|
          unless item.is_a?(String)
            errors.add(:filters, "all values in '#{key}' must be strings")
          end
        end
      end
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
    end

    def validate_originated_on
      return if filters.nil? || !filters.key?('originatedOn')

      originated_on = filters['originatedOn']

      unless originated_on.is_a?(Array)
        errors.add(:filters, 'originatedOn must be an array')
        return
      end

      # Validate each range string format
      originated_on.each do |range_string|
        unless range_string.is_a?(String)
          errors.add(:filters, 'all originatedOn values must be strings')
          next
        end

        # Validate format: 'YYYY-MM-DDTHH:MM:SS.sssZ TO YYYY-MM-DDTHH:MM:SS.sssZ'
        unless range_string.match?(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z TO \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/)
          errors.add(:filters, "originatedOn range '#{range_string}' must be in format 'YYYY-MM-DDTHH:MM:SS.sssZ TO YYYY-MM-DDTHH:MM:SS.sssZ'")
        end
      end
    end
  end
end
