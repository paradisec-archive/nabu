class RegistrationsController < Devise::RegistrationsController
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
end
