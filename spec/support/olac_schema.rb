require 'helpers/olac_schema_helpers'

RSpec.configure do |config|
  config.include OlacSchemaHelpers, type: :request
end
