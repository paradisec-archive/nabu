require 'factory_bot'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # SHouldn't need this but it's not working in Rails 7.1
  config.before(:suite) do
    FactoryBot.find_definitions
  end
end
