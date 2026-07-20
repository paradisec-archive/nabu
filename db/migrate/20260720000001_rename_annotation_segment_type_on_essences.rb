class RenameAnnotationSegmentTypeOnEssences < ActiveRecord::Migration[8.0]
  # The segments extension in the RO-Crate API spec renamed the 'annotation' segment type to
  # 'time-aligned-annotation'; rewrite the stored segments JSON to match. Rows need reindexing
  # afterwards (rake search:reindex or the extracted-content backfill).
  def up
    rewrite('"type":"annotation"', '"type":"time-aligned-annotation"')
  end

  def down
    rewrite('"type":"time-aligned-annotation"', '"type":"annotation"')
  end

  private

  def rewrite(from, to)
    connection.update(<<~SQL.squish)
      UPDATE essences SET extracted_content = REPLACE(extracted_content, '#{from}', '#{to}')
      WHERE extracted_content_type = 'elan'
    SQL
  end
end
