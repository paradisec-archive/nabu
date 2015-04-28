class RemoveScheduledReportsTable < ActiveRecord::Migration
  def up
    drop_table :scheduled_reports
  end

  def down
  end
end
