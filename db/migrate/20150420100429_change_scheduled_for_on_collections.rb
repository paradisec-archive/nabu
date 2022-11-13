class ChangeScheduledForOnCollections < ActiveRecord::Migration[4.2]
  def up
    change_column :scheduled_reports, :scheduled_for, :string, null: false
  end

  def down
    change_column :scheduled_reports, :scheduled_for, :datetime, null: false
  end
end
