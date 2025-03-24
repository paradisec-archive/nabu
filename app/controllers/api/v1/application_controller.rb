module Api
  module V1
    class ApplicationController < ::ApplicationController
      skip_before_action :verify_authenticity_token

      prepend_before_action :doorkeeper_authorize_optional

      private

      def doorkeeper_authorize_optional
        if doorkeeper_token
          doorkeeper_authorize! # triggers normal Doorkeeper validation
        end
      end

      def authenticated
        !!doorkeeper_token&.id
      end

      def admin_authenticated
        authenticated && doorkeeper_token.scopes&.include?('admin')
      end

      def current_user
        if doorkeeper_token
          @current_user ||= User.find_by(id: doorkeeper_token[:resource_owner_id])
        end
      end
    end
  end
end
