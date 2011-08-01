source 'http://rubygems.org'

gem 'rails', '3.1.0.rc5'

gem 'mysql2'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', "~> 3.1.0.rc"
  gem 'compass', :git => 'https://github.com/chriseppstein/compass.git', :branch => 'rails31'

  gem 'coffee-rails', "~> 3.1.0.rc"
  gem 'uglifier'
end

gem 'jquery-rails'

gem 'haml-rails'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

group :development, :test do
  gem 'sqlite3'

  gem 'cucumber-rails'
  gem 'rspec'
  gem 'database_cleaner'

  # Guard
  gem 'guard-cucumber'
  gem 'rb-inotify' if RUBY_PLATFORM.downcase.include?('linux')
  gem 'libnotify' if RUBY_PLATFORM.downcase.include?('linux')
  gem 'rb-fsevent' if RUBY_PLATFORM.downcase.include?('darwin')
  gem 'growl' if RUBY_PLATFORM.downcase.include?('darwin')

  # Pretty printed test output
  gem 'turn', :require => false
end
