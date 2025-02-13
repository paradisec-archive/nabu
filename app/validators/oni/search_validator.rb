module Oni
  class SearchValidator
    include ActiveModel::Validations

    # NOTE: We remap name to title below to match the database column
    SORT_FIELDS = %w[id title created_at updated_at relevance].freeze
    ORDER_FIELDS = %w[asc desc].freeze

    ATTRIBUTES = %i[search_type query filters limit offset order sort].freeze
    attr_accessor(*ATTRIBUTES)

    validate :validate_filters

    validates :order, inclusion: { in: ORDER_FIELDS, message: '%{value} is not a valid order' }, allow_nil: true
    validates :sort, inclusion: { in: SORT_FIELDS, message: '%{value} is not a valid sort field' }, allow_nil: true
    validates :limit, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 1000 }, allow_nil: true
    validates :offset, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

    def initialize(params)
      permitted = ATTRIBUTES.map { | attr| attr.to_s.camelize(:lower).to_sym }
      filters = { languages: [], countries: [], collector_names: [] }
      object_params = params.permit(permitted, filters:)
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
  end
end
