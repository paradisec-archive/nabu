class ChangeCollectionsMediaToText < ActiveRecord::Migration[8.1]
  def up
    change_column :collections, :media, :text
  end

  def down
    change_column :collections, :media, :string, limit: 255
  end
end
