RSpec.configure do |config|
  config.before(type: :system) do
    driven_by :rack_test
  end

  config.include Capybara::RSpecMatchers, type: :request
end
