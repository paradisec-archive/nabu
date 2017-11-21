class ExpandSessionStore < ActiveRecord::Migration
  def up
    change_column :sessions, :data, :text, limit: 4.megabytes
  end

  def down
  end
end
