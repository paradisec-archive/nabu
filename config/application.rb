require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Nabu
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    ###################
    # Out Stuff
    ###################

    ActiveSupport::Dependencies.autoload_paths << File::join( Rails.root, 'app', 'services')
    ActiveSupport::Dependencies.autoload_paths << File::join( Rails.root, 'lib')

    config.viewer_url = '/viewer'

    config.assets.precompile << 'delayed/web/application.css'

    ## Proxyist
    config.proxyist_url = ENV.fetch('PROXYIST_URL')
    throw 'Must set PROXYIST_URL' unless config.proxyist_url
  end
end

require 'monkeypatch'
