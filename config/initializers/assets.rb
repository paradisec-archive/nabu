# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

###################
#### Our Stuff
###################

Rails.application.config.assets.precompile += %w[active_admin.css active_admin.js per_page.js jquery-query.js maps.js]
Rails.application.config.assets.precompile += %w[screen.css print.css ie.css]
Rails.application.config.assets.precompile += %w[query_builder.js advanced_search.js advanced_search.js.coffee]
