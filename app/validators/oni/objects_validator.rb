module Oni
  class ObjectsValidator
    include ActiveModel::Validations

    # NOTE: We remap name to title below to match the database column
    SORT_FIELDS = %w[id name title originated_on].freeze
    ORDER_FIELDS = %w[asc desc].freeze
    ENTITY_TYPES = %w[http://pcdm.org/models#Collection http://pcdm.org/models#Object].freeze

    ATTRIBUTES = %i[member_of entity_type limit offset order sort].freeze
    attr_accessor(*ATTRIBUTES)

    validates :member_of, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_nil: true
    validates :entity_type, inclusion: { in: ENTITY_TYPES, message: '%{value} is not a valid conformsTo' }, allow_nil: true
    validates :order, inclusion: { in: ORDER_FIELDS, message: '%{value} is not a valid order' }, allow_nil: true
    validates :sort, inclusion: { in: SORT_FIELDS, message: '%{value} is not a valid sort field' }, allow_nil: true
    validates :limit, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 1000 }, allow_nil: true
    validates :offset, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

    def initialize(params)
      object_params = params.permit(*ATTRIBUTES.map { | attr| attr.to_s.camelize(:lower).to_sym })
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

      @limit ||= 1000
      @offset ||= 0
      @order ||= 'asc'
      @sort ||= 'title'
    end
  end
end
