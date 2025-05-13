class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern
  # NOTE: nabu needs to support old browsers due to regional context

  before_action :set_timezone
  before_action :set_access_headers
  before_action :set_sentry_user
  before_action :validate_per_page_param

  private

  ##########
  # For Active Admin
  ##########

  def authenticate_admin_user!
    redirect_to new_user_session_path unless current_user&.admin?
  end

  def current_admin_user
    current_user
  end

  ##########
  # Devise redirect after login
  ##########

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || dashboard_path
  end

  ##########
  # CanCan
  ##########

  rescue_from CanCan::AccessDenied do |exception|
    # If it's a JSON request, give a 40x rather than redirecting them
    if request.format.symbol == :json && current_user
      render nothing: true, status: :forbidden
    elsif request.format.symbol == :json
      render nothing: true, status: :unauthorized
    elsif current_user
      redirect_to root_url, alert: exception.message
    else
      session['user_return_to'] = request.fullpath
      redirect_to new_user_session_path, alert: exception.message
    end
  end

  ##########
  # Before Actions
  ##########

  def set_timezone
    Time.zone = current_user.time_zone if current_user
  end

  def set_access_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end

  def set_sentry_user
    Sentry.set_user(id: current_user.id, email: current_user.email) if current_user
  end

  def validate_per_page_param
    fields = %i[per_page items_page page files_per_page]
    fields.each do |name|
      next unless params[name]

      begin
        params[name] = params[name].to_i
      rescue StandardError
        params.delete(name)
        next
      end

      params[name] = 1000 if params[name] && params[name] > 1000

      params.delete(name) if params[name].zero?
    end
  end

  ############
  # used by collections_controller and items_controller for creating Collectors and Agents
  ############
  def create_contact(name)
    name = name.gsub(/^NEWCONTACT:/, '')

    last_space = name.rindex(' ')
    if last_space
      first_name = name[0..last_space - 1]
      last_name = name[last_space + 1..]
    else
      first_name = name
    end

    contact = User.where(first_name:, last_name:).first
    if contact.nil?
      random_string = SecureRandom.base64(16)
      contact = User.create!({
                               first_name:,
                               last_name:,
                               password: random_string,
                               password_confirmation: random_string,
                               contact_only: true
                             })
    end

    contact.id
  end
end
