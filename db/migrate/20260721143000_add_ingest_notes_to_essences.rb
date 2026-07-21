class AddIngestNotesToEssences < ActiveRecord::Migration[8.1]
  def change
    add_column :essences, :ingest_notes, :text, size: :long
  end
end
