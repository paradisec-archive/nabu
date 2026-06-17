class HardenMembershipTablesWithCascadingForeignKeys < ActiveRecord::Migration[8.1]
  MEMBERSHIP_TABLES = %i[collection_admins collection_users item_admins item_users].freeze

  # item_admins/item_users only index user_id via the composite (item_id, user_id)
  # index, which can't back a user_id foreign key. Add a standalone index with a
  # conventional name so MySQL doesn't auto-create one named after the constraint.
  USER_ID_INDEX_TABLES = %i[item_admins item_users].freeze

  # Each membership/grant table and the parent tables its columns reference.
  MEMBERSHIP_FOREIGN_KEYS = {
    collection_admins: { collections: :collection_id, users: :user_id },
    collection_users: { collections: :collection_id, users: :user_id },
    item_admins: { items: :item_id, users: :user_id },
    item_users: { items: :item_id, users: :user_id }
  }.freeze

  def up
    # users.id is a bigint, so the referencing user_id columns must be widened to
    # match before a foreign key can be added.
    MEMBERSHIP_TABLES.each do |table|
      change_column table, :user_id, :bigint, null: false
    end

    USER_ID_INDEX_TABLES.each do |table|
      add_index table, :user_id, name: "index_#{table}_on_user_id"
    end

    MEMBERSHIP_FOREIGN_KEYS.each do |table, references|
      references.each do |parent_table, column|
        # Remove orphan rows so the constraint can be added.
        execute(<<~SQL.squish)
          DELETE child FROM #{table} child
          LEFT JOIN #{parent_table} parent ON child.#{column} = parent.id
          WHERE parent.id IS NULL
        SQL

        add_foreign_key table, parent_table, column: column, on_delete: :cascade
      end
    end
  end

  def down
    MEMBERSHIP_FOREIGN_KEYS.each do |table, references|
      references.each do |parent_table, column|
        remove_foreign_key table, parent_table, column: column
      end
    end

    USER_ID_INDEX_TABLES.each do |table|
      remove_index table, name: "index_#{table}_on_user_id"
    end

    MEMBERSHIP_TABLES.each do |table|
      change_column table, :user_id, :integer, null: false
    end
  end
end
