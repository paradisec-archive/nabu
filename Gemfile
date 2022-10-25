source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.11.3'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.3.13', '< 0.6.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

###################
# Our stuff
###################

# Databases
gem 'graphql'
gem "graphiql-rails"

# Views
gem 'compass-rails'
gem 'haml-rails'
gem 'to-csv', :require => 'to_csv'
gem 'kaminari'
gem 'oai'
gem 'analytical'

# Admin
gem 'country-select'
gem 'activeadmin'
gem 'bootstrap-sass'

# Authentications
gem 'devise'
gem 'cancancan'

# Database improvements
gem 'rails_or'
gem 'squeel'
gem 'nilify_blanks'

# Search
gem 'sunspot_rails'
gem 'sunspot_solr'

# Media Detection
gem 'ruby-filemagic'

# Deployment
gem 'capistrano', '~> 2'
gem 'capistrano-unicorn'
gem 'capistrano-rbenv', '~> 1'

# Logging
gem 'rollbar'
gem 'newrelic_rpm'

# Misc
gem 'progress_bar'
gem 'paper_trail'
gem 'quiet_assets'
gem 'roo'
# Unpublished version used for ability to use StringIO. https://github.com/roo-rb/roo-xls/pull/7
gem 'roo-xls'
gem 'streamio-ffmpeg'
gem 'rake'
gem 'timeliness'

# Image processing
gem 'rmagick'

# Scheduling
gem 'whenever', :require => false

# Background processing
gem 'delayed_job_active_record'
gem 'daemons'

# TODO: We should probably move to cookie sessions
gem 'activerecord-session_store'

group :development, :test do
  gem 'test-unit'
  gem 'turn', :require => false
  gem 'rspec-rails'
  gem 'thin'

  gem 'spring-commands-rspec'

  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-rails'

  gem 'letter_opener'

  gem 'rb-inotify', :require => RUBY_PLATFORM.include?('linux') ? 'rb-inotify' : false
  gem 'rb-fsevent', :require => RUBY_PLATFORM.include?('darwin') ? 'rb-fsevent' : false
end

group :development do
  # Guard
  gem 'guard'
  gem 'guard-rails'
  gem 'guard-rspec'
  gem 'guard-sunspot', :git => 'https://github.com/mackinleysmith/guard-sunspot.git'

  gem 'annotate'
  gem 'binding_of_caller'
  gem 'better_errors'
  gem 'traceroute' # Helps find unused routes and controller actions
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
