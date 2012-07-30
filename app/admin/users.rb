ActiveAdmin.register User do
  scope :users
  scope :contacts
  scope :admins
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
    default_actions
  end

  show do |user|
    attributes_table do
      row :id
      row :first_name
      row :last_name
      row :address
      row :address2
      row :country
      row :email
      row :unconfirmed_email
      row :phone
      row :rights_transferred_to
      row :rights_transfer_reason
      row :contact_only
      row :admin
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
end
