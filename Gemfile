source 'http://rubygems.org'

gem 'rails', '3.1.1'

gem 'mysql2'
# For heroku
gem 'pg'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.1.4'
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier', '>= 1.0.3'
  gem 'compass', '~> 0.12.alpha'
end

gem 'jquery-rails'

gem 'haml-rails'

gem 'devise'
gem 'cancan'

gem 'squeel'

gem 'to_csv-rails'

gem 'kaminari'


# Use unicorn as the web server
gem 'unicorn'

# Deploy with Capistrano
gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

group :development, :test do
  gem 'sqlite3'

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
  gem 'rb-inotify' if RUBY_PLATFORM.downcase.include?('linux')
  gem 'libnotify' if RUBY_PLATFORM.downcase.include?('linux')
  gem 'rb-fsevent' if RUBY_PLATFORM.downcase.include?('darwin')
  gem 'growl' if RUBY_PLATFORM.downcase.include?('darwin')

  # Pretty printed test output
  gem 'turn', :require => false
end
