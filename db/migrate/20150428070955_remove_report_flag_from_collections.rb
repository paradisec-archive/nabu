class RemoveReportFlagFromCollections < ActiveRecord::Migration
  def up
    remove_column :collections, :sends_report
  end

  def down
  end
end
