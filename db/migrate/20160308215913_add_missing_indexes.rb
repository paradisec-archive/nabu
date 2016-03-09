class AddMissingIndexes < ActiveRecord::Migration
  def change
    add_index :collections, :access_condition_id
    add_index :grants, :collection_id
    add_index :grants, :funding_body_id
    add_index :grants, [:collection_id, :funding_body_id]
    add_index :users, :rights_transferred_to_id
    add_index :items, :collector_id
    add_index :items, :operator_id
    add_index :items, :university_id
    add_index :items, :access_condition_id
    add_index :items, :discourse_type_id
    add_index :comments, [:commentable_id, :commentable_type]
    add_index :comments, :owner_id
  end
end
