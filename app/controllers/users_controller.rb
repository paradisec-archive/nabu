class UsersController < ApplicationController
  load_and_authorize_resource :except => :show

  respond_to :json, :html

  def index
    @users = @users.order('first_name, last_name')
    match = "%#{params[:q]}%"
    @users = @users.where{ (first_name =~ match) | (last_name =~ match)  | (address =~ match) | (address2 =~ match) | (country =~ match) | (email =~ match)}

    respond_to do |format|
      format.html
      format.json do
        render :json => @users.map {|u| {:id => u.id, :name => u.name}}
      end
    end
  end

  def show
    @user = User.find params[:id]
    respond_to do |format|
      format.html do
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
      result = @user.update_attributes(params[:user], :as => current_user.admin? ? :admin : nil)
    elsif not current_password.blank?
      @user.attributes = params[:user]
      @user.valid?
      @user.errors.add(:current_password, current_password.blank? ? :blank : :invalid)
      result = false
    else
      result = @user.update_attributes(params[:user], :as => current_user.admin? ? :admin : nil)
    end

    if result
      flash[:notice] = 'User was successfully updated.'
      sign_in :user, @user, :bypass => true if current_user == @user
      redirect_to @user
    else
      render :action => 'edit'
    end
  end

  def merge
    @primary_user = @user || User.find(params[:id])
    dups = User.duplicates_of(@primary_user.first_name, @primary_user.last_name)
    @merge_user = MergeUser.new(dups)

    if params[:user]
      # get the updated parameters from the form merge
      @primary_user.assign_attributes(params[:user], :as => current_user.admin? ? :admin : nil)

      # then do all the underlying ownership changes
      if UserMergerService.new(@primary_user, dups).call
        redirect_to edit_user_path, notice: "Successfully merged user! [#{@primary_user.name}]"
      else
        redirect_to merge_user_path, alert: "Failed to merge user! [#{@primary_user.name}]"
      end
    end
  end
end
