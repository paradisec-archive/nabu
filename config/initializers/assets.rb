# # Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# https://github.com/rails/cssbundling-rails/issues/120
Rails.application.config.assets.paths << Rails.root.join('node_modules', 'select2')
Rails.application.config.assets.paths << Rails.root.join('node_modules', 'jquery-ui')
