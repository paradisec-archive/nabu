require_relative 'production'

Nabu::Application.configure do
  config.action_mailer.default_url_options = { host: 'nabu-stage.paradisec.org.au' }

  # Enable more logging in staging
  config.active_record.verbose_query_logs = true
  config.active_record.query_log_tags_enabled = true
  config.active_job.verbose_enqueue_logs = true
  config.log_level = :debug
end
