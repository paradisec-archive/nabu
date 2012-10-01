class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :make_action_mailer_use_request_host
  before_filter :set_timezone

  private
  def make_action_mailer_use_request_host
    ActionMailer::Base.default_url_options[:host] = request.host_with_port
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  def set_timezone
    Time.zone = current_user.time_zone if current_user
  end

  def sort_column(model)
    model.sortable_columns.include?(params[:sort]) ? [params[:sort]] : model.sortable_columns[0, 2]
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : "asc"
  end

  def authenticate_active_admin_user!
    redirect_to new_user_session_path unless current_user && current_user.admin?
  end

  def after_sign_in_path_for(resource)
   dashboard_path
  end
end
