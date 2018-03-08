source 'https://rubygems.org'

gem 'rails', '~> 3.2.22.2'

# Databases
gem 'mysql2', '~> 0.3.17'
gem 'graphql'
gem "graphiql-rails"

group :assets do
  gem 'coffee-rails', '~> 3.2.1'
  gem 'compass-rails'

  gem 'therubyracer'
  gem 'libv8'

  gem 'uglifier', '>= 1.0.3'
end

# Views
gem 'jquery-rails'
gem 'haml-rails'
gem 'to-csv', :require => 'to_csv'
gem 'kaminari'
gem 'oai'
gem 'analytical'

# Admin
gem 'country-select'
gem 'activeadmin'
gem 'bootstrap-sass'
gem 'sass-rails',  '~> 3.2.3'
gem 'meta_search', '>= 1.1.0.pre'

# Authentications
gem 'devise', '2.2.3'
gem 'cancancan', '~> 1.13.1'

# Database improvements
gem 'rails_or'
gem 'squeel'
gem 'nilify_blanks'

# Search
gem 'sunspot_rails'
gem 'sunspot_solr'

# Web Server
gem 'unicorn'

# Media Detection
gem 'ruby-filemagic'

# Deployment
gem 'capistrano'
gem 'capistrano-unicorn'
gem 'capistrano-rbenv'

# Logging
gem 'rollbar'
gem 'newrelic_rpm'

# Misc
gem 'progress_bar'
gem 'paper_trail', '~> 2'
gem 'quiet_assets'
gem 'roo', '~> 2.1.0'
# Unpublished version used for ability to use StringIO. https://github.com/roo-rb/roo-xls/pull/7
gem 'roo-xls', :github => 'roo-rb/roo-xls', :ref => '0a5ef88'
gem 'streamio-ffmpeg'
gem 'rake', '< 11.0'
gem 'timeliness'

# Image processing
gem 'rmagick'

# Scheduling
gem 'whenever', :require => false

# Background processing
gem 'delayed_job_active_record'
gem 'daemons'

group :development, :test do
  gem 'turn', '~> 0.8.3', :require => false
  gem 'rspec-rails', '~> 2.0'
  gem 'sextant'
  gem 'thin'

  gem 'spring'
  gem 'spring-commands-rspec'

  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-rails'

  gem 'letter_opener'

  # Guard
  gem 'guard-bundler'
  gem 'guard-rails'
  gem 'guard-rspec'
  gem 'guard-sunspot'

  gem 'rb-inotify', :require => RUBY_PLATFORM.include?('linux') ? 'rb-inotify' : false
  gem 'rb-fsevent', :require => RUBY_PLATFORM.include?('darwin') ? 'rb-fsevent' : false

  # Tool for writing clean and consistent HAML
  gem 'haml_lint', '>= 0.18.0', require: false
end

group :development do
  gem 'annotate'
  gem 'binding_of_caller'
  gem 'better_errors'
  # A Rake task gem that helps you find the unused routes and controller actions for your Rails 3+ app
  # Pull request allows ignoring of various devise things.
  gem 'traceroute', github: 'distributedlife/traceroute', :ref => '94eb4e66e13c590e07d3b76cc154d2e32d5c5c21'
  gem 'rubocop'
end

group :test do
  gem 'capybara'
  gem 'poltergeist'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'launchy'
end
