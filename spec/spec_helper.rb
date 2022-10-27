# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'factory_bot'
require 'database_cleaner'

require 'rspec/rails'
require 'rspec/autorun' unless defined?(Zeus)

require 'helpers/expectation_helpers'

require 'sunspot'

require 'capybara/rspec'
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.include Devise::TestHelpers, :type => :controller
  config.include DeviseFeatureMacros #, :type => :feature
  config.include ExpectationHelpers

  # So we can use routes in tests
  config.include Rails.application.routes.url_helpers
  config.include Capybara::DSL


  include Warden::Test::Helpers

  Warden.test_mode!

  config.before(:suite) do
    # Do truncation once per suite to vacuum for Postgres
    DatabaseCleaner.clean_with :truncation
    # Normally do transactions-based cleanup
    # DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    # FIXME: we want transaction but it's not worling well, deal with after upgrades
    DatabaseCleaner.strategy = :truncation
  end
  #
  # config.before(:each, type: :feature) do
  #   # :rack_test driver's Rack app under test shares database connection
  #   # with the specs, so continue to use transaction strategy for speed.
  #   driver_shares_db_connection_with_specs = Capybara.current_driver == :rack_test
  #
  #   unless driver_shares_db_connection_with_specs
  #     # Driver is probably for an external browser with an app
  #     # under test that does *not* share a database connection with the
  #     # specs, so use truncation strategy.
  #     DatabaseCleaner.strategy = :truncation
  #   end
  # end
  #
  # config.before(:each) do
  #   DatabaseCleaner.start
  # end
  #
  # config.append_after(:each) do
  #   DatabaseCleaner.clean
  # end

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  #config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false # set to false to allow database cleaner to do its thing

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
