class ExpandSessionStore < ActiveRecord::Migration[4.2]
  def up
    change_column :sessions, :data, :text, limit: 4.megabytes
  end

  def down
  end
end
