class MakeMetadataExportableNonNullableOnItems < ActiveRecord::Migration[8.1]
  def up
    Item.where(metadata_exportable: nil).in_batches.update_all(metadata_exportable: false)
    change_column_default :items, :metadata_exportable, from: nil, to: false
    change_column_null :items, :metadata_exportable, false
  end

  def down
    change_column_null :items, :metadata_exportable, true
    change_column_default :items, :metadata_exportable, from: false, to: nil
  end
end
