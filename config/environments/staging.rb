require_relative 'production'

Nabu::Application.configure do
  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_mailer.default_url_options = { :host => 'staging.paradisec.org.au' }
end
