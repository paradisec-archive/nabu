# ## Schema Information
#
# Table name: `users`
#
# ### Columns
#
# Name                            | Type               | Attributes
# ------------------------------- | ------------------ | ---------------------------
# **`id`**                        | `bigint`           | `not null, primary key`
# **`address`**                   | `string(255)`      |
# **`address2`**                  | `string(255)`      |
# **`admin`**                     | `boolean`          | `default(FALSE), not null`
# **`collector`**                 | `boolean`          | `default(FALSE), not null`
# **`confirmation_sent_at`**      | `datetime`         |
# **`confirmation_token`**        | `string(255)`      |
# **`confirmed_at`**              | `datetime`         |
# **`contact_only`**              | `boolean`          | `default(FALSE)`
# **`country`**                   | `string(255)`      |
# **`current_sign_in_at`**        | `datetime`         |
# **`current_sign_in_ip`**        | `string(255)`      |
# **`email`**                     | `string(255)`      |
# **`encrypted_password`**        | `string(255)`      | `default(""), not null`
# **`failed_attempts`**           | `integer`          | `default(0)`
# **`first_name`**                | `string(255)`      | `not null`
# **`last_name`**                 | `string(255)`      |
# **`last_sign_in_at`**           | `datetime`         |
# **`last_sign_in_ip`**           | `string(255)`      |
# **`locked_at`**                 | `datetime`         |
# **`party_identifier`**          | `string(255)`      |
# **`phone`**                     | `string(255)`      |
# **`remember_created_at`**       | `datetime`         |
# **`reset_password_sent_at`**    | `datetime`         |
# **`reset_password_token`**      | `string(255)`      |
# **`rights_transfer_reason`**    | `string(255)`      |
# **`sign_in_count`**             | `integer`          | `default(0)`
# **`unconfirmed_email`**         | `string(255)`      |
# **`unikey`**                    | `string(255)`      |
# **`unlock_token`**              | `string(255)`      |
# **`created_at`**                | `datetime`         | `not null`
# **`updated_at`**                | `datetime`         | `not null`
# **`rights_transferred_to_id`**  | `integer`          |
#
# ### Indexes
#
# * `index_users_on_confirmation_token` (_unique_):
#     * **`confirmation_token`**
# * `index_users_on_email` (_unique_):
#     * **`email`**
# * `index_users_on_reset_password_token` (_unique_):
#     * **`reset_password_token`**
# * `index_users_on_rights_transferred_to_id`:
#     * **`rights_transferred_to_id`**
# * `index_users_on_unikey` (_unique_):
#     * **`unikey`**
# * `index_users_on_unlock_token` (_unique_):
#     * **`unlock_token`**

# rubocop:disable Metrics/BlockLength
ActiveAdmin.register User do
  # show scoped buttons on index page
  scope :users
  scope :contacts
  scope :admins
  scope :collectors
  scope :unconfirmed
  scope :never_signed_in

  permit_params :party_identifiers_attributes, :email, :first_name, :last_name,
                :address, :address2, :country, :phone, :password, :password_confirmation, :remember_me, :unconfirmed_email,
                :rights_transferred_to_id, :rights_transfer_reason, :admin, :contact_only, :party_identifier, :collector, :unikey

  before_destroy :check_dependent

  controller do
    def check_dependent(object)
      return unless object.owned_items.count.positive?

      flash[:error] = 'ERROR: User owns items - cannot be removed.'
      false
    end
  end

  # add pagination buttons to index page sidebar
  sidebar :paginate, only: :index do
    count = User.count
    count = User.public_send(params[:scope].to_sym).count if params[:scope].present?

    ['10', '50', "all #{count}"].each do |n|
      para link_to "Show #{n}", params.permit!.merge(per_page: n.sub('all ', ''), page: n.start_with?('all') ? 1 : params[:page]), class: 'button'
    end
  end

  # change pagination
  before_action only: :index do
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

  action_item :merge do
    if %w[show edit].include?(params[:action]) && (User.duplicates_of(resource.first_name, resource.last_name).count > 1)
      link_to 'Merge User', merge_admin_user_path, style: 'float: right;'
    end
  end

  action_item :reset do
    link_to 'Reset Password', reset_password_admin_user_path, style: 'float: right;' if %w[show edit].include?(params[:action])
  end

  member_action :reset_password, method: :get do
    @user = resource || User.find(params[:id])
  end

  member_action :do_reset_password, method: :patch do
    @user = resource || User.find(params[:id])
    @user.assign_attributes(password: params[:user][:password], password_confirmation: params[:user][:password_confirmation])
    if @user.save
      redirect_to admin_user_path(@user), notice: 'Password was successfully reset'
    else
      redirect_to reset_password_admin_user_path(@user), alert: "Failed to reset password:\n- #{@user.errors.full_messages.join("\n- ")}"
    end
  end

  member_action :merge, method: :get do
    @primary_user = resource || User.find(params[:id])
    @duplicates = User.duplicates_of(@primary_user.first_name, @primary_user.last_name, params[:specific_user_ids].try(:split, ','))
    @merge_user = MergeUser.new(@duplicates)
    # so we don't merge the primary one
    @duplicates = @duplicates.reject { |d| d.id == @primary_user.id }
  end

  member_action :do_merge, method: :patch do
    if params[:user]
      ids_to_merge = params[:user].delete(:to_merge) # extract the user ids to merge

      @primary_user ||= resource || User.find(params[:id])
      # get the updated parameters from the form merge
      @primary_user.assign_attributes(permitted_params[:user])

      if ids_to_merge.present? && UserMergerService.new(@primary_user, User.find(ids_to_merge)).call
        redirect_to edit_admin_user_path, notice: "Successfully merged user! [#{@primary_user.name}]"
        return
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
    # TODO: uncomment once this stuff is tested in staging
    # column :party_identifiers do |user|
    #   user.party_identifiers.map{|p| p.identifier}.join(', ')
    # end
    actions do |user|
      link_to 'Merge', merge_admin_user_path(user)
    end
  end

  # show page
  show do |_user|
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
      row :unikey
      # TODO: uncomment once this stuff is tested in staging
      # row :party_identifiers do |user|
      #   user.party_identifiers.map{|p| p.identifier}.join("\n")
      # end
    end

    h3 'Admin information'
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
    f.inputs 'User Details' do
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
      if f.object.new_record?
        f.input :password
        f.input :password_confirmation
      end
      f.input :party_identifier
      f.input :unikey
      # TODO: uncomment once this stuff is tested in staging
      # f.has_many :party_identifiers, allow_destroy: true do |p|
      #   p.input :user_id, as: :hidden, input_html: {value: f.object.id}
      #   p.input :party_type, as: :select, collection: PartyIdentifier::TYPES.each_with_index.map{|t,i| [t,i]}
      #   p.input :identifier, as: :string
      # end
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
    # TODO: uncomment once this stuff is tested in staging
    # column :party_identifiers do |user|
    #   user.party_identifiers.map{|p| p.identifier}.join(';')
    # end
  end
end
# rubocop:enable Metrics/BlockLength
