require_relative 'production'

Nabu::Application.configure do
  config.action_mailer.default_url_options = { host: 'nabu-stage.paradisec.org.au' }
end
