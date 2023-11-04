class AddUnikeyToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :unikey, :string
    add_index :users, :unikey, unique: true
  end
end
