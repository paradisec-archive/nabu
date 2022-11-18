class RemovePasswordSaltFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :password_salt, :string
  end
end
