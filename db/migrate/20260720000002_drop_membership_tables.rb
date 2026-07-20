class DropMembershipTables < ActiveRecord::Migration[8.1]
  # Point of no return for the Phase 2 permissions cutover: the four old membership tables
  # were left in place (dead, no reads or writes) as a rollback escape hatch. Deliberately
  # irreversible — the data now lives in `permissions`.
  def up
    drop_table :collection_admins
    drop_table :collection_users
    drop_table :item_admins
    drop_table :item_users
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
