class CreateItemUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :item_users do |t|
      t.belongs_to :item,   :null => false
      t.belongs_to :user,   :null => false
    end
    add_index :item_users, [:item_id, :user_id], :unique => :true
  end
end
