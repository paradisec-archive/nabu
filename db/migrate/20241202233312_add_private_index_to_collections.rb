class AddPrivateIndexToCollections < ActiveRecord::Migration[8.0]
  def change
    add_index :collections, :private, name: 'index_collections_on_private'

    add_index :items, [:collection_id, :private, :updated_at]
  end
end
