module Api
  module V1
    class ApplicationController < ::ApplicationController
      skip_before_action :verify_authenticity_token

      prepend_before_action :doorkeeper_authorize!

      private

      def authenticated
        !!doorkeeper_token.id
      end

      def admin_authenticated
        authenticated && doorkeeper_token.scopes&.include?('admin')
      end

      def current_user
        @current_user ||= User.find_by(id: doorkeeper_token[:resource_owner_id])
      end
    end
  end
end
