module Api
  module V1
    class ApplicationController < ::ApplicationController
      skip_before_action :verify_authenticity_token

      before_action :doorkeeper_authorize!
    end
  end
end
