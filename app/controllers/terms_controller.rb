class TermsController < ApplicationController
  before_action :authenticate_user!

  def show
    @page_title = 'Nabu - Terms and Conditions'
  end

  def accept
    if params[:agree] == '1'
      current_user.accept_terms!
      redirect_to stored_location_for(:user) || dashboard_path
    else
      flash[:error] = 'You must agree to the PDSC access form before you can continue'
      redirect_to terms_path
    end
  end
end
