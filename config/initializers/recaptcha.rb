Recaptcha.configure do |config|
  config.skip_verify_env << 'development' if ENV['RECAPTCHA_DISABLED'] == 'true'
end
