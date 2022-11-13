class AddReportFlagToCollections < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :sends_report, :boolean, default: false
  end
end
