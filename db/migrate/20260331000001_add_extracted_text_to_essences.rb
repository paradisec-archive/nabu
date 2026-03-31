class AddExtractedTextToEssences < ActiveRecord::Migration[8.0]
  def change
    add_column :essences, :extracted_text, :longtext
  end
end
