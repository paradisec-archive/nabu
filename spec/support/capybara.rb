require 'capybara/rspec'
require 'capybara/apparition'

Capybara.register_driver :apparition do |app|
  Capybara::Apparition::Driver.new(app, browser_options: { 'no-sandbox' => nil, 'disable-web-security' => nil, 'disable-features' => 'VizDisplayCompositor' })
end

Capybara.javascript_driver = :apparition

RSpec.configure do |config|
  config.include Capybara::DSL
end
