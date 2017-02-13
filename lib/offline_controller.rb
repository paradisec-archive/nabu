class OfflineController < ActionController::Base
  include ApplicationHelper
  include AbstractController::Rendering
  include ActionController::Helpers
  include CanCan::ControllerAdditions

  append_view_path ActionView::FileSystemResolver.new('app/views')

  def initialize(*args)
    super()
  end

  def current_user
    @current_user ||= User.admins.first
  end
end