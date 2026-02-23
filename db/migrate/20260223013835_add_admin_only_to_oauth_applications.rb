# frozen_string_literal: true

class AddAdminOnlyToOauthApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :oauth_applications, :admin_only, :boolean, null: false, default: false
  end
end
