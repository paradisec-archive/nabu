source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.4'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 6.1.7'
# Use mysql as the database for Active Record
gem 'mysql2', '~> 0.5'
# Use Puma as the app server
gem 'puma', '~> 5.0'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 5.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'rack-mini-profiler', '~> 2.0'
  gem 'listen', '~> 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.26'
  gem 'selenium-webdriver', '>= 4.0.0.rc1'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
#gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

###################
# Our stuff
###################

# Databases
gem 'graphql'
gem "graphiql-rails"

# Views
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
gem 'nilify_blanks'

# Search
gem 'sunspot_rails'

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
  gem 'rails-controller-testing'
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
  gem 'guard-rails', :require => false
  gem 'guard-rspec', :require => false

  gem 'annotate'
  gem 'binding_of_caller'
  gem 'better_errors'
  gem 'traceroute' # Helps find unused routes and controller actions
  gem 'rubocop-rails', :require => false
  gem 'rubocop-rake', :require => false
  gem 'rubocop-rspec', :require => false
end

group :test do
  gem 'apparition', github: 'twalpole/apparition'
  gem 'factory_bot_rails'
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'launchy'
end
