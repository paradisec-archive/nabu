source 'https://rubygems.org'

gem 'rails', '3.2.9'

# Databases
gem 'mysql2'

group :assets do
  gem 'coffee-rails', '~> 3.2.1'
  gem 'compass-rails'

  gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
end

# Views
gem 'jquery-rails'
gem 'haml-rails'
gem 'to-csv', :require => 'to_csv'
gem 'kaminari'
#gem 'oai', :git => 'https://github.com/code4lib/ruby-oai' # FIxes iconv warning. Remove when > 0.2.1 comes out
gem 'oai', :git => 'https://github.com/johnf/ruby-oai', :branch => 'xml_whitespace' # Fixes #10 in XML revert to above when merged https://github.com/code4lib/ruby-oai/pull/25
gem 'analytical'

# Admin
gem 'country-select'
gem 'activeadmin'
gem 'sass-rails',  '~> 3.2.3'
gem 'meta_search', '>= 1.1.0.pre'

# Authentications
gem 'devise'
gem 'cancan'

# Database improvements
gem 'squeel'
gem 'nilify_blanks'


# Search
gem 'sunspot_rails'
# FIXME move back to development once solr is running standalone on the server
gem 'sunspot_solr'

# Web Server
gem 'unicorn'

# Media Detection
gem 'ruby-filemagic'

# Deployment
gem 'capistrano'
gem 'capistrano-unicorn'

# Misc
gem 'progress_bar'
gem 'paper_trail', '~> 2'
gem 'quiet_assets'

group :development, :test do
  gem 'thin'
  gem 'sqlite3'
  gem 'turn', '~> 0.8.3', :require => false
  gem 'sextant'
end

group :test do
  gem 'rspec-rails', '~> 2.0'
  gem 'factory_girl_rails'
  gem 'email_spec'
  gem 'launchy'

  # Guard
  gem 'guard-bundler'
  gem 'guard-rails'
  gem 'guard-spin'
end
