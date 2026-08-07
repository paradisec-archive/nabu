class AddTimestampIndexesForCatalogReport < ActiveRecord::Migration[8.0]
  def change
    add_index :essences, :created_at
    add_index :essences, :updated_at
    add_index :items, :created_at
    add_index :items, :updated_at
    add_index :collections, :created_at
    add_index :collections, :updated_at
  end
end
