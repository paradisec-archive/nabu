class AddReportFlagToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :sends_report, :boolean, default: false
  end
end
