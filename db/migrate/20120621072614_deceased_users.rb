class DeceasedUsers < ActiveRecord::Migration[4.2]
  def change
    change_table :users do |t|
      t.belongs_to :rights_transferred_to, class_name: 'User'
      t.string :rights_transfer_reason
    end
    remove_column :users, :operator
  end
end
