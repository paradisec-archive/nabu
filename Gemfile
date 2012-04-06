source 'http://rubygems.org'

gem 'rails', '3.2.3'

# Databases
gem 'mysql2'
gem 'pg'      # For heroku

group :assets do
  gem 'coffee-rails', '~> 3.2.1'
  gem 'compass-rails'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
end

# Views
gem 'jquery-rails'
gem 'haml-rails'
gem 'to_csv-rails'
gem 'kaminari'
gem 'opinio'

# Admin
gem 'activeadmin'
gem 'sass-rails',  '~> 3.2.3'
gem 'meta_search', '>= 1.1.0.pre'

# Authentications
gem 'devise'
gem 'cancan'

# Database improvements
gem 'squeel'

# Search
gem 'sunspot_rails'
gem 'sunspot_with_kaminari'

# Web Server
gem 'unicorn'

# Deployment
gem 'capistrano'

# Misc
gem 'progress_bar'
gem 'paper_trail', '~> 2'

group :development, :test do
  gem 'thin'
  gem 'sqlite3'
  gem 'sunspot_solr'
  gem 'turn', '~> 0.8.3', :require => false
end

group :test do
  gem 'cucumber-rails'
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'pickle'
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'launchy'

  # Guard
  gem 'guard-cucumber'
  gem 'guard-bundler'
  gem 'guard-rails'
end
