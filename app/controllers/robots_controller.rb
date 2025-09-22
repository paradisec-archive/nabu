class RobotsController < ApplicationController
  def index
    render 'index', content_type: 'text/plain'
  end
end

