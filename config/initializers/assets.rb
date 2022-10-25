# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
config.assets.precompile += %w[active_admin.css active_admin.js per_page.js jquery-query.js maps.js]
config.assets.precompile += %w[screen.css print.css ie.css]
config.assets.precompile += %w[query_builder.js advanced_search.js advanced_search.js.coffee]
