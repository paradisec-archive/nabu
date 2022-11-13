class ExpandVersionsTable < ActiveRecord::Migration[4.2]
  def up
    change_column :versions, :object, :text, limit: 1.megabyte
    change_column :versions, :object_changes, :text, limit: 2.megabytes
  end

  def down
  end
end
