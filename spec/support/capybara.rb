require 'capybara/rspec'

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new(args: %w[headless=new no-sandbox disable-dev-shm-usage window-size=1400,1000])

  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

Capybara.javascript_driver = :headless_chrome

RSpec.configure do |config|
  config.include Capybara::DSL
end
