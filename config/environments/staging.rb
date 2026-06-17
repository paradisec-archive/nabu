require_relative 'production'

Nabu::Application.configure do
  config.action_mailer.default_url_options = { host: 'admin-catalog.nabu-stage.paradisec.org.au' }

  # Enable more logging in staging
  config.active_record.verbose_query_logs = true
  config.active_record.query_log_tags_enabled = true
  config.active_job.verbose_enqueue_logs = true
  config.log_level = :debug

  config.oni_url = 'https://catalog.nabu-stage.paradisec.org.au'

  # Staging may hold a verbatim clone of the production database (see bin/aws/db_sync).
  # Rewrite every outbound recipient so a cloned DB can never email a real user.
  config.action_mailer.interceptors = ['StagingMailInterceptor']
end
