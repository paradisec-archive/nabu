class RemoveScheduledReportsTable < ActiveRecord::Migration[4.2]
  def up
    drop_table :scheduled_reports
  end

  def down
  end
end
