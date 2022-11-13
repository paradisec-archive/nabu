class AddContactOnlyToUsers < ActiveRecord::Migration[4.2]
  def change
    change_table :users do |t|
      t.boolean :contact_only, :default => false
    end
  end
end
