class RenameExtractedTextToExtractedContentOnEssences < ActiveRecord::Migration[8.0]
  def up
    rename_column :essences, :extracted_text, :extracted_content
    add_column :essences, :extracted_content_type, :string

    # Backfill in batches so no single transaction scans and locks the whole table on deploy.
    loop do
      updated = connection.update(<<~SQL.squish)
        UPDATE essences SET extracted_content_type = 'text'
        WHERE extracted_content IS NOT NULL AND extracted_content_type IS NULL
        LIMIT 10000
      SQL

      break if updated.zero?
    end
  end

  def down
    remove_column :essences, :extracted_content_type
    rename_column :essences, :extracted_content, :extracted_text
  end
end
