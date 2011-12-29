class AddArchiveInfoToItems < ActiveRecord::Migration
  def change
    change_table :items do |t|
      t.boolean  :metadata_exportable
      t.boolean  :born_digital
      t.boolean  :tapes_returned
      t.text     :original_media
      t.datetime :received_on
      t.datetime :digitised_on
      t.text     :ingest_notes
      t.datetime :metadata_imported_on
      t.datetime :metadata_exported_on
      t.text     :tracking
    end
  end
end
