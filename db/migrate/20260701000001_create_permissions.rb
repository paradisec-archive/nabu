class CreatePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :permissions, id: :integer do |t|
      t.bigint :user_id, null: false
      t.string :grantable_type, null: false
      t.integer :grantable_id, null: false
      t.string :level, null: false

      t.timestamps
    end

    add_index :permissions, :user_id
    add_index :permissions, %i[grantable_type grantable_id user_id level], unique: true, name: 'index_permissions_on_grantable_and_user_and_level'

    # grantable is polymorphic (Collection or Item), so no database foreign key is possible;
    # the user_id foreign key mirrors the four old membership tables (ON DELETE => cascade).
    add_foreign_key :permissions, :users, column: :user_id, on_delete: :cascade
  end
end
