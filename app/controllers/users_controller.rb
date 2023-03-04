class UsersController < ApplicationController
  load_and_authorize_resource :except => :show

  respond_to :json, :html

  def index
    @users = @users.order('first_name, last_name')
    match = "%#{params[:q]}%"
    @users = @users.where(User.arel_table[:first_name].matches(match))
      .or(@users.where(User.arel_table[:last_name].matches(match)))
      .or(@users.where(User.arel_table[:address].matches(match)))
      .or(@users.where(User.arel_table[:address2].matches(match)))
      .or(@users.where(User.arel_table[:country].matches(match)))
      .or(@users.where(User.arel_table[:email].matches(match)))

    respond_to do |format|
      format.html
      format.json do
        @users = @users.limit(100)
        render :json => @users.map {|u| {:id => u.id, :name => u.display_label}}
      end
    end
  end

  def show
    @user = User.find params[:id]
    respond_to do |format|
      format.html do
        @page_title = 'Nabu - User Details'
        authorize! :show, @user
        render 'users/edit'
      end
      format.json do
        render :json => {:id => @user.id, :name => @user.name}
      end
    end
  end

  def edit
  end

  def update
    #TODO FInd a better way to do this. Most of this logic is copied from devise so we can use protected attributes properly

    current_password = params[:user].delete(:current_password)

    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation) if params[:user][:password_confirmation].blank?
    end

    if current_password and (@user.valid_password?(current_password) or current_user.admin?)
      result = @user.update(params[:user], :as => current_user.admin? ? :admin : nil)
    elsif not current_password.blank?
      @user.attributes = params[:user]
      @user.valid?
      @user.errors.add(:current_password, current_password.blank? ? :blank : :invalid)
      result = false
    else
      result = @user.update(params[:user], :as => current_user.admin? ? :admin : nil)
    end

    if result
      flash[:notice] = 'User was successfully updated.'
      sign_in :user, @user, :bypass => true if current_user == @user
      redirect_to @user
    else
      @page_title = 'Nabu - User Details'
      render :action => 'edit'
    end
  end

  def user_params
    params = [:party_identifiers_attributes, :first_name, :last_name, :password, :password_confirmation, :party_identifier, :collector]
    if (user.contact_only?)
      params << :contact_only
    else
      params.push(*[:email, :address, :address2, :country, :phone,:remember_me])
    end

    params.require(:user).permit(params)
  end
end
