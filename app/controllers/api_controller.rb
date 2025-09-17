# Used for Machine to Machine Oauth access which is based on scopes
class ApplicationUser
  attr_reader :application, :scopes

  def initialize(application, scopes = [])
    @application = application
    @scopes = scopes
  end

  def admin?
    scopes.include?('admin')
  end

  def time_zone
    'Sydney'
  end

  def email
    "#{application.id}-#{application.name}@paradisec.org.au"
  end

  def id
    "application_#{application.id}"
  end

  def to_key
    key = respond_to?(:id) && id
    key ? Array(key) : nil
  end

  def authenticatable_salt
  end

  # Mimic user interface if needed
  # def persisted?
  #   true
  # end
end

class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token

  prepend_before_action :doorkeeper_authorize_optional
  prepend_before_action :set_current_user

  private

  def doorkeeper_authorize_optional
    # We still want to proceed if there's no token, so we can have public endpoints
    if doorkeeper_token
      doorkeeper_authorize!
    end
  end

  def set_current_user
    return if current_user

    # They have  browser session
    @current_user ||= if !doorkeeper_token
      nil
    elsif doorkeeper_token.resource_owner_id
      # Regular user authentication
      User.find_by(id: doorkeeper_token[:resource_owner_id])
    else
      ApplicationUser.new(doorkeeper_token.application, doorkeeper_token.scopes.to_a)
    end
  end
end
