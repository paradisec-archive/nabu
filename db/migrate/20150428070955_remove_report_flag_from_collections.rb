class RemoveReportFlagFromCollections < ActiveRecord::Migration[4.2]
  def up
    remove_column :collections, :sends_report
  end

  def down
  end
end
