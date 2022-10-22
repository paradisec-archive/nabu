require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Nabu
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    ###################
    # Out Stuff
    ###################

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
