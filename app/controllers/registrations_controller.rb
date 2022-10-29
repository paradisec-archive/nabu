class RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters

  def create
    uri = URI.parse("https://www.google.com/recaptcha/api/siteverify")
    response = Net::HTTP.post_form(uri, 'secret' => "6LctF0kaAAAAAMJ9vKkJE6QFvDMepSSJMOJRXzeL", 'response' => params['g-recaptcha-response'])

    if !JSON.parse(response.body)['success']
      build_resource
      resource.errors.add :base, "reCAPTCHA verification failed"
      respond_with resource
    else
      super
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
  end
end
