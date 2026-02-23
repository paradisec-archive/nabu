# frozen_string_literal: true

Rails.application.config.to_prepare do
  Doorkeeper::ApplicationsController.class_eval do
    private

    def application_params
      params.require(:doorkeeper_application)
        .permit(:name, :redirect_uri, :scopes, :confidential, :admin_only)
    end
  end

  Doorkeeper::AuthorizationsController.class_eval do
    before_action :check_admin_only_application

    private

    def check_admin_only_application
      return unless params[:client_id].present?

      application = Doorkeeper::Application.find_by(uid: params[:client_id])
      return unless application&.admin_only?
      return if current_resource_owner&.admin?

      render :admin_only_error, locals: { application: application }, status: :forbidden
    end
  end
end
