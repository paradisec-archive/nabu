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

    # This is the base directory to store the essence files in.
    # They will be stored with a pattern of
    # "/#{collection_id}/#{item_id}/#{filename}" .
    config.archive_directory = "#{Rails.root}/public/system/nabu-archive/"

    # This is the directory from where Nabu will pick up files to save to the
    # structure defined by config.archive_directory . File names have to follow
    # the pattern: "#{collection_id}-#{item_id}-xxx.xxx", so they can be moved
    # into the correct directory.
    # Note: files of the pattern "#{collection_id}-#{item_id}-xxx-PDSC_ADMIN.xxx"
    # will be copied, but not added to the list of imported files in Nabu.
    config.upload_directories = [
      "#{Rails.root}/public/system/send_to_archive/",
      "/tmp/test/"
    ]

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
  end
end

require 'oai_provider'
require 'monkeypatch'
