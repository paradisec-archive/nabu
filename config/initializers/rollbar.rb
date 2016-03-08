require 'rollbar/rails'
Rollbar.configure do |config|
  rollbar_file = "#{Rails.root}/config/shared/rollbar.txt"
  if File.exist? rollbar_file
    config.access_token = File.read(rollbar_file).strip
  else
    ENV['ROLLBAR_ACCESS_TOKEN']
  end

  # Without configuration, Rollbar is enabled by in all environments.
  # To disable in specific environments, set config.enabled=false.
  # Here we'll disable in 'test':
  if Rails.env.test? || Rails.env.development?
    config.enabled = false
  end

  # By default, Rollbar will try to call the `current_user` controller method
  # to fetch the logged-in user object, and then call that object's `id`,
  # `username`, and `email` methods to fetch those properties. To customize:
  # config.person_method = "my_current_user"
  # config.person_id_method = "my_id"
  # config.person_username_method = "my_username"
  # config.person_email_method = "my_email"

  # If you want to attach custom data to all exception and message reports,
  # provide a lambda like the following. It should return a hash.
  # config.custom_data_method = lambda { {:some_key => "some_value" } }

  # Add exception class names to the exception_level_filters hash to
  # change the level that exception is reported at. Note that if an exception
  # has already been reported and logged the level will need to be changed
  # via the rollbar interface.
  # Valid levels: 'critical', 'error', 'warning', 'info', 'debug', 'ignore'
  # 'ignore' will cause the exception to not be reported at all.
  # config.exception_level_filters.merge!('MyCriticalException' => 'critical')

  config.exception_level_filters.merge!('ActionController::RoutingError' => lambda { |e|
    e.message =~ %r(No route matches \[[A-Z]+\] "/(.+)")
    path = $1
    case
    when path =~ /php$/i
      'ignore'
    else
      'warning'
    end
  })

  # Enable asynchronous reporting (uses girl_friday or Threading if girl_friday
  # is not installed)
  # config.use_async = true
  # Supply your own async handler:
  # config.async_handler = Proc.new { |payload|
  #  Thread.new { Rollbar.process_payload(payload) }
  # }
end
