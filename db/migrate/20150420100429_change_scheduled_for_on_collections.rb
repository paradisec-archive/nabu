class ChangeScheduledForOnCollections < ActiveRecord::Migration
  def up
    change_column :scheduled_reports, :scheduled_for, :string, null: false
  end

  def down
    change_column :scheduled_reports, :scheduled_for, :datetime, null: false
  end
end
