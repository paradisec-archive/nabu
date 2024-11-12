# https://github.com/rails/cssbundling-rails/issues/120
Rails.application.config.assets.paths << Rails.root.join('node_modules', 'select2')
Rails.application.config.assets.paths << Rails.root.join('node_modules', 'jquery-ui')
