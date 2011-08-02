class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :make_action_mailer_use_request_host

  def make_action_mailer_use_request_host
    ActionMailer::Base.default_url_options[:host] = request.host_with_port
  end
end
