class AddNameIndexToUsers < ActiveRecord::Migration[8.1]
  def change
    add_index :users, %i[first_name last_name]
  end
end
