require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Nabu
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

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

    # --- NABU APPLICATION SPECIFIC DIRECTORIES BELOW HERE ---
    # This is the directory that Nabu will scan for new files frequently.
    # If it finds files in there that match the pattern
    # "#{collection_id}-#{item_id}-xxx.xxx",
    # it will create an appropriate metadata file
    # e.g.
    # .wav -> .imp.xml
    # .mp3 -> .id3.xml
    # .ogg -> .vorbiscomment (TODO)
    config.scan_directory = "#{Rails.root}/public/system/prepare_for_sealing/"
    config.write_imp = "#{Rails.root}/public/system/XMLImport/"
    config.write_id3 = "#{Rails.root}/public/system/ID3Import/"

    config.viewer_url = '/viewer'

    config.assets.precompile << 'delayed/web/application.css'

    ## Proxyist
    config.proxyist_url = ENV.fetch('PROXYIST_URL')
    throw 'Must set PROXYIST_URL' unless config.proxyist_url
  end
end

require 'monkeypatch'
