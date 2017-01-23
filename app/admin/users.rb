ActiveAdmin.register User do
  # show scoped buttons on index page
  scope :users
  scope :contacts
  scope :admins
  scope :collectors
  scope :all_users

  before_destroy :check_dependent

  controller do
    def check_dependent(object)
      if object.owned_items.count > 0
        flash[:error] = "ERROR: User owns items - cannot be removed."
        return false
      end
    end
  end

  # allow saving admin-only fields in controller
  controller do
    with_role :admin
  end

  # add pagination buttons to index page sidebar
  sidebar :paginate, :only => :index  do
    para button_tag 'Show 10', :class => 'per_page', :data => {:per => 10}
    para button_tag 'Show 50', :class => 'per_page', :data => {:per => 50}
    count = User.count
    unless params[:scope].blank?
      count = User.public_send(params[:scope].to_sym).count
    end
    button_tag "Show all #{count}", :class => 'per_page', :data => {:per => count}
  end

  # change pagination
  before_filter :only => :index do
    @per_page = params[:per_page] || 30
  end

  # index page search sidebar
  filter :first_name
  filter :last_name
  filter :address
  filter :address2
  filter :country
  filter :phone
  filter :email
  filter :unconfirmed_email
  filter :rights_transferred_to
  filter :rights_transfer_reason
  filter :contact_only
  filter :collector
  filter :admin

  action_item do
    if %w(show edit).include?(params[:action])
      if User.duplicates_of(resource.first_name, resource.last_name).count > 1
        link_to 'Merge User', merge_admin_user_path, style: 'float: right;'
      end
      link_to 'Reset Password', reset_password_admin_user_path, style: 'float: right;'
    end
  end

  member_action :reset_password, method: :get do
    @user = resource || User.find(params[:id])
  end

  member_action :do_reset_password, method: :put do
    @user = resource || User.find(params[:id])
    @user.assign_attributes(params[:user])
    if @user.save
      redirect_to edit_admin_user_path(@user), notice: 'Password was successfully reset'
    else
      redirect_to edit_admin_user_path(@user), alert: "Failed to reset password:\n- #{@user.errors.message.join("\n- ")}"
    end
  end

  member_action :merge, method: :get do
    @primary_user = resource || User.find(params[:id])
    @duplicates = User.duplicates_of(@primary_user.first_name, @primary_user.last_name, params[:specific_user_ids].try(:split, ','))
    @merge_user = MergeUser.new(@duplicates)
    # so we don't merge the primary one
    @duplicates = @duplicates.reject {|d| d.id == @primary_user.id}
  end

  member_action :do_merge, method: :put do
    if params[:user]
      ids_to_merge = params[:user].delete(:to_merge) # extract the user ids to merge

      @primary_user ||= resource || User.find(params[:id])
      # get the updated parameters from the form merge
      @primary_user.assign_attributes(params[:user], as: :admin)

      if ids_to_merge and ids_to_merge.present? and UserMergerService.new(@primary_user, User.find(ids_to_merge)).call
        redirect_to edit_admin_user_path, notice: "Successfully merged user! [#{@primary_user.name}]" and return
      else
        flash[:alert] = 'Must select 1 or more duplicate users to perform merge'
      end

      redirect_to merge_admin_user_path
    end
  end

  # index page
  index do
    id_column
    column :first_name
    column :last_name
    column :address
    column :address2
    column :country
    column :email
    column :phone
    column :contact_only
    column :admin
    column :party_identifier
    actions do |user|
      link_to 'Merge', merge_admin_user_path(user)
    end
  end

  # show page
  show do |user|
    attributes_table do
      row :id
      row :first_name
      row :last_name
      row :address
      row :address2
      row :country
      row :phone
      row :email
      row :unconfirmed_email
      row :rights_transferred_to
      row :rights_transfer_reason
      row :collector
      row :contact_only
      row :admin
      row :party_identifier
    end

    h3 "Admin information"
    attributes_table do
      row :created_at
      row :confirmation_sent_at
      row :confirmed_at
      row :updated_at
      row :current_sign_in_at
      row :current_sign_in_ip
      row :last_sign_in_at
      row :last_sign_in_ip
      row :sign_in_count
      row :failed_attempts
      row :locked_at
      row :reset_password_sent_at
    end
  end

  # edit page
  form do |f|
    f.inputs "User Details" do
      f.input :first_name
      f.input :last_name
      f.input :address
      f.input :address2
      f.input :country
      f.input :email
      f.input :unconfirmed_email
      f.input :phone
      f.input :rights_transferred_to
      f.input :rights_transfer_reason
      f.input :collector
      f.input :contact_only
      f.input :admin
      buffer =f.input :party_identifier
      if f.object.new_record?
        f.input :password
        f.input :password_confirmation
      end
      buffer
    end
    f.actions
  end

  # limit fields in csv export
  csv do
    column :id
    column :first_name
    column :last_name
    column :address
    column :address2
    column :country
    column :email
    column :phone
    column :rights_transferred_to
    column :rights_transfer_reason
    column :collector
    column :contact_only
    column :admin
    column :party_identifier
  end
end
