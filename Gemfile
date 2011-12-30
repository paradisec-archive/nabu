source 'http://rubygems.org'

gem 'rails', '3.1.3'

# Databases
gem 'mysql2'
gem 'pg'      # For heroku

group :assets do
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier', '>= 1.0.3'
  gem 'compass', '~> 0.12.alpha.3'
end

# Views
gem 'jquery-rails'
gem 'haml-rails'
gem 'to_csv-rails'
gem 'kaminari'
gem 'opinio', :git => 'git@github.com:johnf/opinio.git' # awaiting pull request ???


# Admin
gem 'activeadmin', :git => 'git://github.com/gregbell/active_admin.git' # remove after 0.4.0 is released (jquery issue)
gem 'sass-rails',  '~> 3.1.5'
gem 'meta_search', '>= 1.1.0.pre'

# Authentications
gem 'devise'
gem 'cancan'

# Database improvements
gem 'squeel'

# Web Server
gem 'unicorn'

# Deployment
gem 'capistrano'
gem 'execjs'
gem 'therubyracer'

group :development, :test do
  gem 'sqlite3'
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
  gem 'rb-inotify', :require => RUBY_PLATFORM.include?('linux') && 'rb-inotify'
  gem 'rb-fsevent', :require => RUBY_PLATFORM.include?('darwin') && 'rb-fsevent'
  gem 'growl', :require => RUBY_PLATFORM.include?('darwin') && 'growl'
end
