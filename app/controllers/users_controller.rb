class UsersController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  def index
    @users = @users.order('first_name, last_name')
    match = "%#{params[:q]}%"
    @users = @users.where(User.arel_table[:first_name].matches(match))
      .or(@users.where(User.arel_table[:last_name].matches(match)))
      .or(@users.where(User.arel_table[:address].matches(match)))
      .or(@users.where(User.arel_table[:address2].matches(match)))
      .or(@users.where(User.arel_table[:country].matches(match)))
      .or(@users.where(User.arel_table[:email].matches(match)))

    @users = @users.limit(100)

    render :json => @users.map {|u| {:id => u.id, :name => u.display_label}}
  end

  def show
    @user = User.find params[:id]

    render :json => {:id => @user.id, :name => @user.display_label}
  end
end
