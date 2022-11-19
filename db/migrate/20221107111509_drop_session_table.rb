class DropSessionTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :sessions, if_exists: true
  end
end
