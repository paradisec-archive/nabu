class AddObjectChangesColumnToVersions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :versions, :object_changes, :text
  end

  def self.down
    remove_column :versions, :object_changes
  end
end
