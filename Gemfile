source 'https://rubygems.org'

ruby '3.2.2'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.1.0'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

# Use mysql as the database for Active Record
gem 'mysql2', '~> 0.5'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mswin jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Sass to process CSS
gem 'sassc-rails'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-ge
  gem 'debug', platforms: %i[mri mswin]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'selenium-webdriver'
end

###################
# Our stuff
###################

# Needs to be as early as possible to do it's job
gem 'dotenv-rails', require: 'dotenv/rails-now' # , groups: [:development, :test] # Load env variables in dev

# Views
gem 'haml-rails', '~> 2.0' # We use HAML for templates instead of erb
gem 'jb' # for json templates, simploer and faster than jbuilder
gem 'kaminari' # Pagination
gem 'oai' # OAI-PMH
gem 'rexml' # OAI needs it https://github.com/code4lib/ruby-oai/issues/68

# Analytics and instrumentation
gem 'sentry-delayed_job'
gem 'sentry-rails'
gem 'sentry-ruby'

# AAA
gem 'cancancan' # Authorisation
gem 'devise' # Authentication
gem 'doorkeeper' # API auth/Oauth2
gem 'recaptcha' # Avoid fake registrations

# Database improvements
gem 'nilify_blanks' # Convert empty strings to NULL in the DB where possible
gem 'paper_trail' # Keep an audit trail of all the changes

# Background processing
gem 'aws-sdk-rails' # Send emails via SES
gem 'daemons' # Needed by delayed_job
gem 'delayed_job_active_record' # Delay jobs and queue them in the database

# Frameworks
gem 'activeadmin'
gem 'country_select'
gem 'delayed-web'
gem 'graphiql-rails', '1.8.0' # https://github.com/rmosolgo/graphiql-rails/issues/106
gem 'graphql'

# Search
gem 'faraday_middleware-aws-sigv4'
gem 'opensearch-ruby'
gem 'searchjoy'
gem 'searchkick'

# Other
gem 'curb' # Download CSVs for import
gem 'rmagick' # Image processing
gem 'roo' # Spreadsheet interface
gem 'roo-xls' # Add excel support to roo
gem 'ruby-filemagic' # Detect file types
gem 'rubyzip' # Zip the large CSV files before emailing
gem 'rufus-scheduler' # Cron
gem 'streamio-ffmpeg' # ffmpeg interface
gem 'whenever', require: false # scheduling

group :development, :test do
  gem 'rails-controller-testing'
  gem 'rspec-rails'
end

group :development do
  gem 'guard'
  gem 'guard-rails', require: false
  gem 'guard-rspec', require: false

  gem 'annotate' # Annotate models with schema
  gem 'letter_opener' # Open emails in browser during development
  gem 'traceroute' # Helps find unused routes and controller actions

  gem 'rubocop-graphql', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false

  gem 'solargraph', require: false
  gem 'sorbet', require: false
  gem 'tapioca', require: false
end

group :test do
  gem 'database_cleaner'
  gem 'factory_bot_rails'
end
