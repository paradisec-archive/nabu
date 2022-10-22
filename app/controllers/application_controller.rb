class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery

  before_filter :make_action_mailer_use_request_host
  before_filter :set_timezone
  before_filter :set_access_headers

  analytical :modules => [:google]

  private
  def make_action_mailer_use_request_host
    ActionMailer::Base.default_url_options[:host] = request.host_with_port
  end

  rescue_from CanCan::AccessDenied do |exception|
    # If it's a JSON request, give a 40x rather than redirecting them
    case
    when request.format.symbol == :json && current_user
      render nothing: true, :status => 403
    when request.format.symbol == :json
      render nothing: true, :status => 401
    when current_user
      redirect_to root_url, :alert => exception.message
    else
      session["user_return_to"] = request.fullpath
      redirect_to new_user_session_path, :alert => exception.message
    end
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
    stored_location_for(resource) || dashboard_path
  end

  # used by collections_controller and items_controller for creating Collectors and Agents
  def create_contact(name)
    name = name.gsub(/^NEWCONTACT:/, '')

    last_space = name.rindex(' ')
    if last_space
      first_name = name[0..last_space-1]
      last_name = name[last_space+1..-1]
    else
      first_name = name
    end

    contact = User.where(:first_name => first_name, :last_name => last_name).first
    if contact.nil?
      random_string = SecureRandom.base64(16)
      contact = User.create!({
        :first_name => first_name,
        :last_name => last_name,
        :password => random_string,
        :password_confirmation => random_string,
        :contact_only => true}, :as => :contact_only)
    end
    contact.id
  end

  def set_access_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end
end
