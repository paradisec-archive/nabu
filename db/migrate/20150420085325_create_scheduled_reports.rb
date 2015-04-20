class CreateScheduledReports < ActiveRecord::Migration
  def up
    create_table :scheduled_reports do |t|
      t.integer :collection_id, null: false
      t.datetime :scheduled_for, null: false
      t.string :frequency
      t.string :report_type, null: false

      t.timestamps
    end
  end
end
