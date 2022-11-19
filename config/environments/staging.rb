require_relative 'production'

Nabu::Application.configure do
  config.action_mailer.default_url_options = { :host => 'staging.paradisec.org.au' }
end
