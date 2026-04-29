class RobotsController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    render 'index', content_type: 'text/plain'
  end
end
