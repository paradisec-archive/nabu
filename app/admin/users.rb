ActiveAdmin.register User do
  # show scoped buttons on index page
  scope :users
  scope :contacts
  scope :admins
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
      count = User.send(params[:scope].to_sym).count
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
  filter :admin

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
    default_actions
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
      f.input :contact_only
      f.input :admin
      f.input :party_identifier
      if !f.object.new_record?
        f.input :password
        f.input :password_confirmation
      end
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
    column :contact_only
    column :admin
    column :party_identifier
  end
end
