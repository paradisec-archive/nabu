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

  private

  def doorkeeper_authorize_optional
    # We still want to proceed if there's no token, so we can have public endpoints
    if doorkeeper_token
      doorkeeper_authorize!
    end
  end

  def set_current_user
    if !doorkeeper_token
      return nil
    end

    # Regular user authentication
    if doorkeeper_token.resource_owner_id
      return User.find_by(id: doorkeeper_token[:resource_owner_id])
    end

    ApplicationUser.new(doorkeeper_token.application, doorkeeper_token.scopes.to_a)
  end


  def current_user
    @current_user ||= set_current_user
  end
end
