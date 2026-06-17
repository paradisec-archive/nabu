class CreateCollectionUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :collection_users, id: :integer do |t|
      t.integer :collection_id, null: false
      t.integer :user_id, null: false
    end

    add_index :collection_users, :collection_id
    add_index :collection_users, :user_id
    add_index :collection_users, %i[collection_id user_id], unique: true, name: 'index_collection_users_on_collection_id_and_user_id'
  end
end
