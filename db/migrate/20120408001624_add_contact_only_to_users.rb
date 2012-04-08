class AddContactOnlyToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.boolean :contact_only, :default => false
    end
  end
end
